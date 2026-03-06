// src/main.cpp
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <vector>
#include <cmath>
#include <cstdlib>
#include <algorithm>
#include <cctype>
#include <unordered_set>
#include <cstdint>

#include "httplib.h"          // cpp-httplib
#include <nlohmann/json.hpp>

namespace fs = std::filesystem;
using json = nlohmann::json;

struct DocChunk {
    std::string id;         // path#chunkIndex
    std::string path;       // file path
    std::string text;       // chunk text
    std::vector<float> vec; // embedding
};

static std::vector<DocChunk> g_index;

// --- small helpers

std::string read_text_file(const fs::path& p) {
    std::ifstream ifs(p, std::ios::binary);
    if (!ifs) return {};
    std::string s((std::istreambuf_iterator<char>(ifs)),
                  std::istreambuf_iterator<char>());
    return s;
}

std::vector<std::string> chunk_text(const std::string& s, size_t chunk = 1000, size_t overlap = 200) {
    std::vector<std::string> out;
    if (s.empty()) return out;
    size_t start = 0;
    while (start < s.size()) {
        size_t end = std::min(start + chunk, s.size());
        out.emplace_back(s.substr(start, end - start));
        if (end == s.size()) break;
        start = end - std::min(overlap, end); // overlap back
    }
    return out;
}

std::string to_valid_utf8(const std::string& in) {
    std::string out;
    out.reserve(in.size());

    size_t i = 0;
    while (i < in.size()) {
        unsigned char c = static_cast<unsigned char>(in[i]);

        if (c <= 0x7F) {
            out.push_back(static_cast<char>(c));
            ++i;
            continue;
        }

        if (c >= 0xC2 && c <= 0xDF) {
            if (i + 1 < in.size()) {
                unsigned char c1 = static_cast<unsigned char>(in[i + 1]);
                if ((c1 & 0xC0) == 0x80) {
                    out.push_back(static_cast<char>(c));
                    out.push_back(static_cast<char>(c1));
                    i += 2;
                    continue;
                }
            }
            out.push_back('?');
            ++i;
            continue;
        }

        if (c >= 0xE0 && c <= 0xEF) {
            if (i + 2 < in.size()) {
                unsigned char c1 = static_cast<unsigned char>(in[i + 1]);
                unsigned char c2 = static_cast<unsigned char>(in[i + 2]);
                bool ok = ((c1 & 0xC0) == 0x80) && ((c2 & 0xC0) == 0x80);
                if (c == 0xE0) ok = ok && (c1 >= 0xA0);
                if (c == 0xED) ok = ok && (c1 <= 0x9F);
                if (ok) {
                    out.push_back(static_cast<char>(c));
                    out.push_back(static_cast<char>(c1));
                    out.push_back(static_cast<char>(c2));
                    i += 3;
                    continue;
                }
            }
            out.push_back('?');
            ++i;
            continue;
        }

        if (c >= 0xF0 && c <= 0xF4) {
            if (i + 3 < in.size()) {
                unsigned char c1 = static_cast<unsigned char>(in[i + 1]);
                unsigned char c2 = static_cast<unsigned char>(in[i + 2]);
                unsigned char c3 = static_cast<unsigned char>(in[i + 3]);
                bool ok = ((c1 & 0xC0) == 0x80) && ((c2 & 0xC0) == 0x80) && ((c3 & 0xC0) == 0x80);
                if (c == 0xF0) ok = ok && (c1 >= 0x90);
                if (c == 0xF4) ok = ok && (c1 <= 0x8F);
                if (ok) {
                    out.push_back(static_cast<char>(c));
                    out.push_back(static_cast<char>(c1));
                    out.push_back(static_cast<char>(c2));
                    out.push_back(static_cast<char>(c3));
                    i += 4;
                    continue;
                }
            }
            out.push_back('?');
            ++i;
            continue;
        }

        out.push_back('?');
        ++i;
    }

    return out;
}

// Call llama.cpp native /embedding endpoint.
// For OpenAI-compatible endpoint, switch to POST /v1/embeddings
// with {"input":"..."} and parse accordingly.  (llama-server docs)
std::optional<std::vector<float>> embed(const std::string& base_url, const std::string& text) {
    httplib::Client cli(base_url.c_str()); // e.g. "http://127.0.0.1:8013"
    cli.set_connection_timeout(2, 0);
    cli.set_read_timeout(30, 0);

    std::string safe_text = to_valid_utf8(text);
    if (safe_text.empty()) return std::nullopt;

    for (int attempt = 0; attempt < 4; ++attempt) {
        // Prefer OpenAI-compatible endpoint used by current llama-server releases.
        json req_openai = {
            {"input", safe_text}
        };

        auto res = cli.Post("/v1/embeddings", req_openai.dump(), "application/json");
        if (res && res->status == 200) {
            try {
                json j = json::parse(res->body);
                return j.at("data").at(0).at("embedding").get<std::vector<float>>();
            } catch (...) {
                std::cerr << "Unexpected /v1/embeddings JSON shape\n";
            }
        } else if (res) {
            bool too_large = (res->status == 500 && res->body.find("input is too large") != std::string::npos);
            if (too_large && safe_text.size() > 160) {
                safe_text.resize(safe_text.size() / 2);
                continue;
            }

            std::cerr << "/v1/embeddings failed status=" << res->status;
            if (!res->body.empty()) {
                std::cerr << " body=" << res->body.substr(0, 220);
            }
            std::cerr << "\n";
        }

        // Fallback to legacy native endpoint.
        json req_legacy = { {"content", safe_text} };
        res = cli.Post("/embedding", req_legacy.dump(), "application/json");
        if (!res || res->status != 200) {
            std::cerr << "Embedding HTTP error";
            if (res) std::cerr << " status=" << res->status;
            std::cerr << "\n";
            return std::nullopt;
        }

        try {
            json j = json::parse(res->body);
            // handle: [{ "embedding": [[...]] }]
            if (j.is_array() && !j.empty()) {
                const auto& embNode = j.at(0).at("embedding");
                if (embNode.is_array() && !embNode.empty() && embNode.at(0).is_array()) {
                    return embNode.at(0).get<std::vector<float>>();
                }
                if (embNode.is_array()) {
                    return embNode.get<std::vector<float>>();
                }
            }
            std::cerr << "Unexpected embedding JSON shape\n";
        } catch (...) {
            std::cerr << "Embedding response is not valid JSON\n";
        }

        return std::nullopt;
    }

    std::cerr << "Embedding input remained too large after retries\n";
    return std::nullopt;
}

float cosine(const std::vector<float>& a, const std::vector<float>& b) {
    if (a.size() != b.size() || a.empty()) return 0.f;
    double dot=0, na=0, nb=0;
    for (size_t i=0;i<a.size();++i) { dot += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i]; }
    if (na==0 || nb==0) return 0.f;
    return static_cast<float>(dot / (std::sqrt(na)*std::sqrt(nb)));
}

struct Hit { size_t idx; float score; };

std::string lower_ascii(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

std::vector<std::string> tokenize_words(const std::string& s) {
    std::vector<std::string> out;
    std::string cur;
    const std::string low = lower_ascii(s);
    for (char c : low) {
        if (std::isalnum(static_cast<unsigned char>(c))) {
            cur.push_back(c);
        } else if (!cur.empty()) {
            if (cur.size() >= 3) out.push_back(cur);
            cur.clear();
        }
    }
    if (!cur.empty() && cur.size() >= 3) out.push_back(cur);
    return out;
}

float lexical_overlap_score(const std::string& question, const std::string& text) {
    static const std::unordered_set<std::string> stop = {
        "the","and","for","with","from","that","this","what","does","tell","tells","about","who","you","your"
    };

    auto qtok = tokenize_words(question);
    auto ttok = tokenize_words(text);
    if (qtok.empty() || ttok.empty()) return 0.f;

    std::unordered_set<std::string> tset(ttok.begin(), ttok.end());
    size_t useful = 0;
    size_t matched = 0;
    for (const auto& token : qtok) {
        if (stop.find(token) != stop.end()) continue;
        ++useful;
        if (tset.find(token) != tset.end()) ++matched;
    }
    if (useful == 0) return 0.f;
    return static_cast<float>(matched) / static_cast<float>(useful);
}

float all_terms_match_bonus(const std::string& question, const std::string& text) {
    static const std::unordered_set<std::string> stop = {
        "the","and","for","with","from","that","this","what","does","tell","tells","about","who","you","your"
    };

    auto qtok = tokenize_words(question);
    auto ttok = tokenize_words(text);
    if (qtok.empty() || ttok.empty()) return 0.f;

    std::unordered_set<std::string> tset(ttok.begin(), ttok.end());
    size_t useful = 0;
    for (const auto& token : qtok) {
        if (stop.find(token) != stop.end()) continue;
        ++useful;
        if (tset.find(token) == tset.end()) return 0.f;
    }
    if (useful >= 2) return 0.25f;
    return 0.f;
}

std::vector<Hit> topk(const std::vector<float>& q, const std::string& question, size_t k=4) {
    std::vector<Hit> hs;
    hs.reserve(g_index.size());
    for (size_t i=0;i<g_index.size();++i) {
        float s_sem = cosine(q, g_index[i].vec);
        float s_lex = lexical_overlap_score(question, g_index[i].text);
        float s_bonus = all_terms_match_bonus(question, g_index[i].text);
        float s = 0.65f * s_sem + 0.35f * s_lex + s_bonus;
        hs.push_back({i, s});
    }
    std::partial_sort(hs.begin(), hs.begin()+std::min(k, hs.size()), hs.end(),
                      [](const Hit& A, const Hit& B){ return A.score > B.score; });
    if (hs.size() > k) hs.resize(k);
    return hs;
}

std::optional<std::string> chat(const std::string& base_url, const std::string& system, const std::string& user) {
    httplib::Client cli(base_url.c_str()); // e.g. "http://127.0.0.1:8012"
    cli.set_connection_timeout(2, 0);
    cli.set_read_timeout(120, 0);

    // OpenAI-compatible /v1/chat/completions (llama-server)
    json req = {
        {"model", "local-llm"},
        {"messages", json::array({
            json{{"role","system"},{"content",system}},
            json{{"role","user"},{"content",user}}
        })},
        {"temperature", 0.2},
        {"max_tokens", 512}
    };

    auto res = cli.Post("/v1/chat/completions", req.dump(), "application/json");
    if (!res || res->status != 200) {
        std::cerr << "Chat HTTP error\n";
        return std::nullopt;
    }
    json j = json::parse(res->body);
    try {
        std::string out = j["choices"][0]["message"]["content"].get<std::string>();

        // Defensive cleanup: remove UTF-8 BOM and leading control bytes only.
        if (out.size() >= 3 &&
            static_cast<unsigned char>(out[0]) == 0xEF &&
            static_cast<unsigned char>(out[1]) == 0xBB &&
            static_cast<unsigned char>(out[2]) == 0xBF) {
            out.erase(0, 3);
        }
        while (!out.empty()) {
            unsigned char c = static_cast<unsigned char>(out.front());
            if ((c < 0x20 && c != '\n' && c != '\t') || c == 0x7F) {
                out.erase(out.begin());
                continue;
            }
            break;
        }

        return out;
    } catch (...) {}
    return std::nullopt;
}

bool parse_port(const std::string& s, int& out_port) {
    char* end = nullptr;
    long v = std::strtol(s.c_str(), &end, 10);
    if (!end || *end != '\0') return false;
    if (v < 1 || v > 65535) return false;
    out_port = static_cast<int>(v);
    return true;
}

bool parse_size_value(const std::string& s, size_t& out_value) {
    char* end = nullptr;
    unsigned long long v = std::strtoull(s.c_str(), &end, 10);
    if (!end || *end != '\0') return false;
    if (v == 0) return false;
    out_value = static_cast<size_t>(v);
    return true;
}

std::int64_t file_mtime_key(const fs::path& p) {
    try {
        return static_cast<std::int64_t>(fs::last_write_time(p).time_since_epoch().count());
    } catch (...) {
        return 0;
    }
}

std::vector<fs::path> collect_doc_files(const std::string& folder) {
    static const std::unordered_set<std::string> ignored_dir_names = {
        ".git", ".svn", ".hg", "node_modules", "build", "dist", "target", "__pycache__", ".venv", "venv"
    };

    std::vector<fs::path> files;
    for (auto it = fs::recursive_directory_iterator(folder); it != fs::recursive_directory_iterator(); ++it) {
        const auto& p = *it;

        if (p.is_directory()) {
            auto name = p.path().filename().string();
            if (!name.empty() && name[0] == '.') {
                it.disable_recursion_pending();
                continue;
            }
            if (ignored_dir_names.find(name) != ignored_dir_names.end()) {
                it.disable_recursion_pending();
                continue;
            }
            continue;
        }

        if (!p.is_regular_file()) continue;
        auto ext = p.path().extension().string();
        if (ext != ".txt" && ext != ".md") continue;

        std::uintmax_t sz = 0;
        try { sz = fs::file_size(p.path()); } catch (...) { continue; }
        if (sz > 256 * 1024) continue;

        files.push_back(p.path());
    }
    std::sort(files.begin(), files.end());
    return files;
}

json make_manifest(const std::vector<fs::path>& files) {
    json m = json::array();
    for (const auto& p : files) {
        std::uintmax_t sz = 0;
        try { sz = fs::file_size(p); } catch (...) {}
        m.push_back({
            {"path", p.string()},
            {"size", sz},
            {"mtime", file_mtime_key(p)}
        });
    }
    return m;
}

std::optional<std::vector<DocChunk>> load_cached_index(const fs::path& cache_path,
                                                       const std::string& emb_base,
                                                       size_t chunk_size,
                                                       size_t chunk_overlap,
                                                       const json& manifest) {
    std::ifstream ifs(cache_path, std::ios::binary);
    if (!ifs) return std::nullopt;

    try {
        json j;
        ifs >> j;
        if (j.value("version", 0) != 1) return std::nullopt;
        if (j.value("emb_base", "") != emb_base) return std::nullopt;
        if (j.value("chunk_size", 0) != chunk_size) return std::nullopt;
        if (j.value("chunk_overlap", 0) != chunk_overlap) return std::nullopt;
        if (!j.contains("manifest") || j.at("manifest") != manifest) return std::nullopt;

        std::vector<DocChunk> out;
        const auto& arr = j.at("chunks");
        if (!arr.is_array()) return std::nullopt;
        out.reserve(arr.size());
        for (const auto& c : arr) {
            out.push_back(DocChunk{
                c.at("id").get<std::string>(),
                c.at("path").get<std::string>(),
                c.at("text").get<std::string>(),
                c.at("vec").get<std::vector<float>>()
            });
        }
        return out;
    } catch (...) {
        return std::nullopt;
    }
}

void save_cached_index(const fs::path& cache_path,
                       const std::string& emb_base,
                       size_t chunk_size,
                       size_t chunk_overlap,
                       const json& manifest,
                       const std::vector<DocChunk>& index) {
    try {
        json chunks = json::array();
        for (const auto& c : index) {
            chunks.push_back({
                {"id", c.id},
                {"path", c.path},
                {"text", c.text},
                {"vec", c.vec}
            });
        }

        json j = {
            {"version", 1},
            {"emb_base", emb_base},
            {"chunk_size", chunk_size},
            {"chunk_overlap", chunk_overlap},
            {"manifest", manifest},
            {"chunks", chunks}
        };

        std::ofstream ofs(cache_path, std::ios::binary | std::ios::trunc);
        ofs << j.dump();
    } catch (...) {
        // ignore cache write errors
    }
}

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "Usage: local_rag [--emb-port <port>] [--chat-port <port>] [--profile <fast|balanced|accurate>] [--top-k <k>] [--max-context-chars <n>] [--reindex] <folder> <question>\n";
        return 1;
    }

    int emb_port = 8013;
    int chat_port = 8012;
    size_t top_k = 4;
    size_t max_context_chars = 12000;
    bool top_k_explicit = false;
    bool max_ctx_explicit = false;
    std::string profile = "balanced";
    bool force_reindex = false;
    std::vector<std::string> positional;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--emb-port") {
            if (i + 1 >= argc || !parse_port(argv[i + 1], emb_port)) {
                std::cerr << "Invalid value for --emb-port\n";
                return 1;
            }
            ++i;
            continue;
        }
        if (arg == "--chat-port") {
            if (i + 1 >= argc || !parse_port(argv[i + 1], chat_port)) {
                std::cerr << "Invalid value for --chat-port\n";
                return 1;
            }
            ++i;
            continue;
        }
        if (arg == "--top-k") {
            if (i + 1 >= argc || !parse_size_value(argv[i + 1], top_k)) {
                std::cerr << "Invalid value for --top-k\n";
                return 1;
            }
            top_k_explicit = true;
            ++i;
            continue;
        }
        if (arg == "--max-context-chars") {
            if (i + 1 >= argc || !parse_size_value(argv[i + 1], max_context_chars)) {
                std::cerr << "Invalid value for --max-context-chars\n";
                return 1;
            }
            max_ctx_explicit = true;
            ++i;
            continue;
        }
        if (arg == "--profile") {
            if (i + 1 >= argc) {
                std::cerr << "Invalid value for --profile\n";
                return 1;
            }
            profile = argv[i + 1];
            if (profile != "fast" && profile != "balanced" && profile != "accurate") {
                std::cerr << "Invalid value for --profile (expected: fast|balanced|accurate)\n";
                return 1;
            }
            ++i;
            continue;
        }
        if (arg == "--reindex") {
            force_reindex = true;
            continue;
        }
        if (!arg.empty() && arg[0] == '-') {
            std::cerr << "Unknown argument: " << arg << "\n";
            std::cerr << "Usage: local_rag [--emb-port <port>] [--chat-port <port>] [--profile <fast|balanced|accurate>] [--top-k <k>] [--max-context-chars <n>] [--reindex] <folder> <question>\n";
            return 1;
        }

        positional.push_back(arg);
    }

    if (positional.size() != 2) {
        std::cerr << "Usage: local_rag [--emb-port <port>] [--chat-port <port>] [--profile <fast|balanced|accurate>] [--top-k <k>] [--max-context-chars <n>] [--reindex] <folder> <question>\n";
        return 1;
    }

    if (!top_k_explicit || !max_ctx_explicit) {
        size_t profile_top_k = 4;
        size_t profile_max_ctx = 12000;
        if (profile == "fast") {
            profile_top_k = 2;
            profile_max_ctx = 4000;
        } else if (profile == "accurate") {
            profile_top_k = 6;
            profile_max_ctx = 20000;
        }

        if (!top_k_explicit) top_k = profile_top_k;
        if (!max_ctx_explicit) max_context_chars = profile_max_ctx;
    }

    const std::string folder = positional[0];
    const std::string question = positional[1];

    const std::string EMB_BASE = "http://127.0.0.1:" + std::to_string(emb_port); // embeddings server
    const std::string CHAT_BASE = "http://127.0.0.1:" + std::to_string(chat_port); // chat server

    constexpr size_t CHUNK_SIZE = 800;
    constexpr size_t CHUNK_OVERLAP = 120;

    auto files = collect_doc_files(folder);
    auto manifest = make_manifest(files);
    fs::path cache_path = fs::path(folder) / ".local_rag_index.json";

    if (!force_reindex) {
        auto cached = load_cached_index(cache_path, EMB_BASE, CHUNK_SIZE, CHUNK_OVERLAP, manifest);
        if (cached) {
            g_index = std::move(*cached);
            std::cout << "Indexed " << g_index.size() << " chunks (cache hit)\n";
        }
    }

    if (g_index.empty()) {
        // 1) Build index from folder
        size_t added = 0;
        for (const auto& p : files) {
            std::string content = read_text_file(p);
            if (content.empty()) continue;

            auto chunks = chunk_text(content, CHUNK_SIZE, CHUNK_OVERLAP);
            int ci = 0;
            for (auto& ch : chunks) {
                auto vec = embed(EMB_BASE, ch);
                if (!vec) continue;
                g_index.push_back(DocChunk{
                    p.string() + "#" + std::to_string(ci++),
                    p.string(),
                    ch,
                    std::move(*vec)
                });
                ++added;
            }
        }
        std::cout << "Indexed " << added << " chunks\n";
        save_cached_index(cache_path, EMB_BASE, CHUNK_SIZE, CHUNK_OVERLAP, manifest, g_index);
    }

    if (g_index.empty()) {
        std::cerr << "No indexed chunks available\n";
        return 2;
    }

    // 2) Query: embed the question
    auto qv = embed(EMB_BASE, question);
    if (!qv) {
        std::cerr << "Failed to embed question\n";
        return 2;
    }

    // 3) Retrieve top-k
    auto hits = topk(*qv, question, top_k);

    // 4) Build context prompt
    std::string context;
    context.reserve(max_context_chars + 256);
    for (auto& h : hits) {
        std::string block = "\n---\nFILE: " + g_index[h.idx].path + "\n" + g_index[h.idx].text + "\n";
        if (context.size() >= max_context_chars) break;

        size_t remaining = max_context_chars - context.size();
        if (block.size() <= remaining) {
            context += block;
        } else {
            context += block.substr(0, remaining);
            break;
        }
    }

    std::string system = "You are a precise assistant. Answer ONLY using the provided CONTEXT. "
                         "If the answer is not present, say you don't know and cite file names.";
    std::string user = "QUESTION:\n" + question + "\n\nCONTEXT:\n" + context + "\n\nAnswer with file citations.";

    // 5) Generate
    auto ans = chat(CHAT_BASE, system, user);
    if (!ans) {
        std::cerr << "Generation failed\n";
        return 3;
    }

    std::cout << "\n=== ANSWER ===\n" << *ans << "\n";
    return 0;
}
