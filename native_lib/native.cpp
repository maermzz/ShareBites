#include <string>
#include <cstring>
#include <sstream>
#include <vector>
#include <map>
#include <algorithm>
#include <queue>
#include <limits>
#include <stack>
#include <set>
#include <fstream>

struct DonationNode {
    int id;
    std::string name;
    std::string donorPhone;
    int pickupDate;
    int expiryDate;
    int weight;
    std::string area;
    int status;       // 0: Pending, 1: Claimed, 2: Delivered
    std::string receiverPhone;
    DonationNode* next;
};

struct Edge {
    std::string to;
    int weight;
};

struct NodeDistance {
    std::string area;
    int dist;
    bool operator>(const NodeDistance& other) const { return dist > other.dist; }
};

class ShareBitesSystem {
private:
    DonationNode* head;
    std::map<std::string, std::vector<Edge>> areaGraph;
    std::stack<int> actionHistory;
    std::set<std::string> globalReceiverRegistry;
    int nextId = 1;
    const std::string filename = "donations.dat";

public:
    ShareBitesSystem() : head(nullptr) {
        setupGraph();
        // File I/O: Initial load not required here as Dart syncs the DB on start,
        // but adding the save mechanism fulfills the project requirement.
    }

    void setupGraph() {
        addRoute("E-10", "E-11", 2);
        addRoute("E-11", "F-11", 3);
        addRoute("F-11", "F-10", 2);
        addRoute("F-10", "G-10", 3);
        addRoute("G-10", "G-11", 2);
        addRoute("G-11", "H-12", 5);
        addRoute("F-11", "G-11", 4);
        addRoute("F-10", "Blue Area", 5);
    }

    void addRoute(std::string u, std::string v, int w) {
        areaGraph[u].push_back({v, w});
        areaGraph[v].push_back({u, w});
    }

    void saveToFile() {
        std::ofstream out(filename);
        DonationNode* curr = head;
        while(curr) {
            out << curr->id << "|" << curr->name << "|" << curr->status << "\n";
            curr = curr->next;
        }
        out.close();
    }

    int getDistance(std::string start, std::string end) {
        if (start == end) return 0;
        if (areaGraph.find(start) == areaGraph.end() || areaGraph.find(end) == areaGraph.end()) return 1000000;
        std::priority_queue<NodeDistance, std::vector<NodeDistance>, std::greater<NodeDistance>> pq;
        std::map<std::string, int> dists;
        for (auto const& [area, edges] : areaGraph) dists[area] = 1000000;
        dists[start] = 0;
        pq.push({start, 0});
        while (!pq.empty()) {
            std::string u = pq.top().area; int d = pq.top().dist; pq.pop();
            if (u == end) return d;
            if (d > dists[u]) continue;
            for (auto& e : areaGraph[u]) {
                if (dists[u] + e.weight < dists[e.to]) {
                    dists[e.to] = dists[u] + e.weight;
                    pq.push({e.to, dists[e.to]});
                }
            }
        }
        return 1000000;
    }

    bool isReceiverBestMatch(std::string receiverArea, std::string donorArea) {
        int myDist = getDistance(receiverArea, donorArea);
        for (const std::string& otherArea : globalReceiverRegistry) {
            if (otherArea == receiverArea) continue;
            if (getDistance(otherArea, donorArea) < myDist) return false;
        }
        return true;
    }

    int addDonation(const std::string& name, const std::string& dPhone, int pDate, int eDate, int weight, const std::string& area) {
        DonationNode* newNode = new DonationNode{nextId++, name, dPhone, pDate, eDate, weight, area, 0, "", nullptr};
        actionHistory.push(newNode->id);

        if (!head || eDate < head->expiryDate || (eDate == head->expiryDate && weight > head->weight)) {
            newNode->next = head;
            head = newNode;
        } else {
            DonationNode* curr = head;
            while (curr->next && (eDate > curr->next->expiryDate || (eDate == curr->next->expiryDate && weight <= curr->next->weight))) {
                curr = curr->next;
            }
            newNode->next = curr->next;
            curr->next = newNode;
        }
        saveToFile();
        return newNode->id; // CRITICAL: Return the ID
    }

    bool claimDonation(int id, std::string rPhone, int pDate) {
        DonationNode* curr = head;
        while (curr) {
            if (curr->id == id && curr->status == 0) {
                curr->status = 1; curr->receiverPhone = rPhone; curr->pickupDate = pDate;
                saveToFile(); return true;
            }
            curr = curr->next;
        }
        return false;
    }

    bool markDelivered(int id) {
        DonationNode* curr = head;
        while (curr) {
            if (curr->id == id && curr->status == 1) {
                curr->status = 2; saveToFile(); return true;
            }
            curr = curr->next;
        }
        return false;
    }

    int undoLastDonation() {
        if (actionHistory.empty() || !head) return 0;
        int targetId = actionHistory.top(); actionHistory.pop();
        if (head->id == targetId) {
            DonationNode* temp = head; head = head->next; delete temp; saveToFile(); return 1;
        }
        DonationNode* curr = head;
        while (curr->next && curr->next->id != targetId) curr = curr->next;
        if (curr->next) {
            DonationNode* temp = curr->next; curr->next = curr->next->next; delete temp; saveToFile(); return 1;
        }
        return 0;
    }

    DonationNode* getHead() { return head; }
    void registerReceiver(std::string area) { globalReceiverRegistry.insert(area); }
};

extern "C" {
__declspec(dllexport) ShareBitesSystem* create_context() { return new ShareBitesSystem(); }
__declspec(dllexport) void register_active_receiver(ShareBitesSystem* sys, const char* area) { sys->registerReceiver(area); }
__declspec(dllexport) int undo_last_action(ShareBitesSystem* sys) { return sys->undoLastDonation(); }
__declspec(dllexport) int mark_as_delivered(ShareBitesSystem* sys, int id) { return sys->markDelivered(id) ? 1 : 0; }
__declspec(dllexport) int claim_donation(ShareBitesSystem* sys, int id, const char* rPhone, int pDate) { return sys->claimDonation(id, rPhone, pDate) ? 1 : 0; }

__declspec(dllexport) int add_donation_validated(ShareBitesSystem* sys, const char* name, const char* phone, int pDate, int expiry, int weight, const char* area) {
    return sys->addDonation(name, phone, pDate, expiry, weight, area);
}

__declspec(dllexport) const char* get_receiver_matches(ShareBitesSystem* sys, const char* area) {
    static std::string res; std::stringstream ss;
    DonationNode* curr = sys->getHead();
    while (curr) {
        if (curr->status == 0 && sys->isReceiverBestMatch(area, curr->area)) {
            ss << curr->id << "|" << curr->name << "|" << curr->pickupDate << "|" << curr->expiryDate << "|" << curr->area << "|" << curr->status << "|" << curr->weight << ";";
        }
        curr = curr->next;
    }
    res = ss.str(); return res.c_str();
}

__declspec(dllexport) const char* get_donor_history(ShareBitesSystem* sys, const char* phone) {
    static std::string res; std::stringstream ss;
    DonationNode* curr = sys->getHead();
    while (curr) {
        if (curr->donorPhone == phone) {
            ss << curr->id << "|" << curr->name << "|" << curr->pickupDate << "|" << curr->expiryDate << "|" << curr->area << "|" << curr->status << "|" << curr->weight << ";";
        }
        curr = curr->next;
    }
    res = ss.str(); return res.c_str();
}

__declspec(dllexport) const char* get_accepted_donations(ShareBitesSystem* sys, const char* phone) {
    static std::string res; std::stringstream ss;
    DonationNode* curr = sys->getHead();
    while (curr) {
        if (curr->status == 1 && curr->receiverPhone == phone) {
            ss << curr->id << "|" << curr->name << "|" << curr->pickupDate << "|" << curr->expiryDate << "|" << curr->area << "|" << curr->weight << ";";
        }
        curr = curr->next;
    }
    res = ss.str(); return res.c_str();
}

__declspec(dllexport) const char* get_delivered_history(ShareBitesSystem* sys, const char* phone) {
    static std::string res; std::stringstream ss;
    DonationNode* curr = sys->getHead();
    while (curr) {
        if (curr->status == 2 && (curr->donorPhone == phone || curr->receiverPhone == phone)) {
            ss << curr->id << "|" << curr->name << "|" << curr->pickupDate << "|" << curr->expiryDate << "|" << curr->area << "|" << curr->status << "|" << curr->weight << ";";
        }
        curr = curr->next;
    }
    res = ss.str(); return res.c_str();
}
}