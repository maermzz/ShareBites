/* #include <vector>
#include <queue>
#include <unordered_map>
#include <string>
#include <cstring>
#include <sstream>
#include <fstream>
#include <limits>
#include <algorithm>

// Structure to hold donation data
struct Donation {
    int id;
    char name[100];
    char donorPhone[20];
    char receiverPhone[20];
    int pickupDate;        // Set when claimed
    int expiryDate;
    char area[100];
    int weight;            // Tracked for UI and donor stats
    int status;            // 0=Pending, 1=Claimed, 2=Delivered
};

// Comparison logic for priority queue (Earliest expiry first)
struct DonationComp {
    bool operator()(const Donation& a, const Donation& b) {
        if (a.expiryDate == b.expiryDate) return a.id > b.id;
        return a.expiryDate > b.expiryDate;
    }
};

// Context to maintain state and adjacency list for Dijkstra
struct NativeContext {
    std::vector<Donation> database;
    std::unordered_map<std::string, std::vector<std::pair<std::string, int>>> adj;
    int nextId = 1;
    std::string dbPath = "donations.dat"; // The file where data is stored
};

// Dijkstra Algorithm to calculate shortest path distance between areas
int calculate_distance(NativeContext* ctx, const std::string& start, const std::string& end) {
    if (start == end) return 0;
    if (ctx->adj.find(start) == ctx->adj.end()) return -1;

    std::unordered_map<std::string, int> dist;
    for (auto const& [key, val] : ctx->adj) dist[key] = 999999;
    dist[start] = 0;

    using PII = std::pair<int, std::string>;
    std::priority_queue<PII, std::vector<PII>, std::greater<PII>> pq;
    pq.push({0, start});

    while (!pq.empty()) {
        int d = pq.top().first;
        std::string u = pq.top().second;
        pq.pop();

        if (u == end) return d;
        if (d > dist[u]) continue;

        for (auto& edge : ctx->adj[u]) {
            if (dist[u] + edge.second < dist[edge.first]) {
                dist[edge.first] = dist[u] + edge.second;
                pq.push({dist[edge.first], edge.first});
            }
        }
    }
    return -1;
}

// --- PERSISTENCE LOGIC ---
// This writes the RAM data to the Hard Drive
void save_to_file(NativeContext* ctx) {
    std::ofstream outFile(ctx->dbPath, std::ios::binary | std::ios::trunc);
    if (outFile.is_open()) {
        outFile.write(reinterpret_cast<const char*>(&ctx->nextId), sizeof(int));
        size_t size = ctx->database.size();
        outFile.write(reinterpret_cast<const char*>(&size), sizeof(size_t));
        if (size > 0) {
            outFile.write(reinterpret_cast<const char*>(ctx->database.data()), size * sizeof(Donation));
        }
        outFile.close();
    }
}

// This reads the Hard Drive data back into RAM on startup
void load_from_file(NativeContext* ctx) {
    std::ifstream inFile(ctx->dbPath, std::ios::binary);
    if (inFile.is_open()) {
        inFile.read(reinterpret_cast<char*>(&ctx->nextId), sizeof(int));
        size_t size = 0;
        inFile.read(reinterpret_cast<char*>(&size), sizeof(size_t));
        if (size > 0) {
            ctx->database.resize(size);
            inFile.read(reinterpret_cast<char*>(ctx->database.data()), size * sizeof(Donation));
        }
        inFile.close();
    }
}

extern "C" {

__declspec(dllexport) void* create_context() {
    auto* ctx = new NativeContext();

    // Initialize graph edges
    ctx->adj["F-10"] = {{"F-11", 5}, {"G-10", 3}, {"Blue Area", 8}};
    ctx->adj["F-11"] = {{"F-10", 5}, {"E-11", 4}};
    ctx->adj["G-10"] = {{"F-10", 3}, {"I-8", 12}};
    ctx->adj["I-8"] = {{"G-10", 12}, {"Blue Area", 10}};
    ctx->adj["Blue Area"] = {{"F-10", 8}, {"I-8", 10}};

    load_from_file(ctx); // LOAD DATA FROM DISK
    return ctx;
}

__declspec(dllexport) int add_donation_validated(void* handle, const char* name, const char* donorPhone, int eDate, int weight, int status, const char* area) {
    auto* ctx = static_cast<NativeContext*>(handle);
    Donation d;
    d.id = ctx->nextId++;
    strncpy_s(d.name, name, 99);
    strncpy_s(d.donorPhone, donorPhone, 19);
    d.receiverPhone[0] = '\0';
    d.pickupDate = 0;
    d.expiryDate = eDate;
    d.weight = weight;
    strncpy_s(d.area, area, 99);
    d.status = 0;

    ctx->database.push_back(d);
    save_to_file(ctx); // SAVE TO DISK
    return d.id;
}

__declspec(dllexport) int claim_donation(void* handle, int id, const char* receiverPhone, int pDate) {
    auto* ctx = static_cast<NativeContext*>(handle);
    for (auto& d : ctx->database) {
        if (d.id == id && d.status == 0) {
            d.status = 1;
            d.pickupDate = pDate;
            strncpy_s(d.receiverPhone, receiverPhone, 19);
            save_to_file(ctx); // SAVE TO DISK
            return 1;
        }
    }
    return 0;
}

__declspec(dllexport) int mark_as_delivered(void* handle, int id) {
    auto* ctx = static_cast<NativeContext*>(handle);
    for (auto& d : ctx->database) {
        if (d.id == id && d.status == 1) {
            d.status = 2;
            save_to_file(ctx); // SAVE TO DISK
            return 1;
        }
    }
    return 0;
}

__declspec(dllexport) const char* get_receiver_matches(void* handle, const char* receiverArea) {
    auto* ctx = static_cast<NativeContext*>(handle);
    static std::string buffer;
    std::priority_queue<Donation, std::vector<Donation>, DonationComp> matches;
    for (const auto& d : ctx->database) {
        if (d.status == 0) {
            int dist = calculate_distance(ctx, receiverArea, d.area);
            if (dist >= 0) matches.push(d);
        }
    }
    std::stringstream ss;
    while (!matches.empty()) {
        Donation d = matches.top(); matches.pop();
        ss << d.id << "|" << d.name << "|" << d.pickupDate << "|" << d.expiryDate << "|" << d.area << "|" << d.weight << ";";
    }
    buffer = ss.str();
    return buffer.c_str();
}

__declspec(dllexport) const char* get_donor_history(void* handle, const char* donorPhone) {
    auto* ctx = static_cast<NativeContext*>(handle);
    static std::string buffer;
    std::stringstream ss;
    for (const auto& d : ctx->database) {
        if (strcmp(d.donorPhone, donorPhone) == 0) {
            ss << d.id << "|" << d.name << "|" << d.pickupDate << "|" << d.expiryDate << "|" << d.area << "|" << d.status << "|" << d.weight << ";";
        }
    }
    buffer = ss.str();
    return buffer.c_str();
}

__declspec(dllexport) const char* get_accepted_donations(void* handle, const char* receiverPhone) {
    auto* ctx = static_cast<NativeContext*>(handle);
    static std::string buffer;
    std::stringstream ss;
    for (const auto& d : ctx->database) {
        if (d.status == 1 && strcmp(d.receiverPhone, receiverPhone) == 0) {
            ss << d.id << "|" << d.name << "|" << d.pickupDate << "|" << d.expiryDate << "|" << d.area << "|" << d.weight << ";";
        }
    }
    buffer = ss.str();
    return buffer.c_str();
}

__declspec(dllexport) const char* get_delivered_history(void* handle, const char* phone) {
    auto* ctx = static_cast<NativeContext*>(handle);
    static std::string buffer;
    std::stringstream ss;
    for (const auto& d : ctx->database) {
        if (d.status == 2 && (strcmp(d.receiverPhone, phone) == 0 || strcmp(d.donorPhone, phone) == 0)) {
            ss << d.id << "|" << d.name << "|" << d.pickupDate << "|" << d.expiryDate << "|" << d.area << "|" << d.status << "|" << d.weight << ";";
        }
    }
    buffer = ss.str();
    return buffer.c_str();
}

} // extern "C"
*/