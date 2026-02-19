import SwiftUI
import Foundation

@main
struct TurskaEVProApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// ---------------------------------------------------------
// ROOT TAB VIEW
// ---------------------------------------------------------
struct RootView: View {
    var body: some View {
        TabView {
            PoissonView().tabItem { Label("Poisson", systemImage: "function") }
            OverUnderPoissonView().tabItem { Label("O/U", systemImage: "sum") }
            OddsView().tabItem { Label("Odds", systemImage: "percent") }
            KellyView().tabItem { Label("Kelly", systemImage: "banknote") }
            EVView().tabItem { Label("EV", systemImage: "chart.bar") }
            ArbitraasiView().tabItem { Label("Arb", systemImage: "arrow.triangle.2.circlepath") }
            EdgeView().tabItem { Label("Edge", systemImage: "triangle") }
            TeamXGSeasonView().tabItem { Label("Team xG", systemImage: "sportscourt") }
            TotalLineSelectorView().tabItem { Label("Total", systemImage: "line.3.horizontal.decrease") }
            NoVig2WayView().tabItem { Label("No-Vig", systemImage: "scissors") }
            NoVig1X2View().tabItem { Label("1X2", systemImage: "scissors.circle") }
        }
    }
}

// ---------------------------------------------------------
// HELPERS
// ---------------------------------------------------------
func factorial(_ n: Int) -> Int {
    (1...max(n,1)).reduce(1, *)
}

// ---------------------------------------------------------
// POISSON
// ---------------------------------------------------------
struct PoissonView: View {
    @State private var lambda = ""
    @State private var maxGoals = ""
    @State private var results: [(Int, Double)] = []

    var body: some View {
        Form {
            Section(header: Text("Syötteet")) {
                TextField("λ", text: $lambda).keyboardType(.decimalPad)
                TextField("Max maalimäärä", text: $maxGoals).keyboardType(.numberPad)
                Button("Laske") { calculate() }
            }

            Section(header: Text("Tulokset")) {
                ForEach(results, id: \.0) { r in
                    HStack {
                        Text("\(r.0)")
                        Spacer()
                        Text(String(format: "%.2f %%", r.1 * 100))
                    }
                }
            }
        }
        .navigationTitle("Poisson")
    }

    func calculate() {
        guard let lam = Double(lambda), let maxG = Int(maxGoals) else { return }
        results = (0...maxG).map { k in
            let p = exp(-lam) * pow(lam, Double(k)) / Double(factorial(k))
            return (k, p)
        }
    }
}

// ---------------------------------------------------------
// OVER/UNDER POISSON
// ---------------------------------------------------------
struct OverUnderPoissonView: View {
    @State private var lambda = ""
    @State private var maxN = ""
    @State private var rows: [(Double, Double, Double)] = []

    let lines = [0.5, 1.5, 2.5, 3.5]

    var body: some View {
        Form {
            Section(header: Text("Syötteet")) {
                TextField("λ total", text: $lambda).keyboardType(.decimalPad)
                TextField("Max laskenta", text: $maxN).keyboardType(.numberPad)
                Button("Laske") { calculate() }
            }

            Section(header: Text("Tulokset")) {
                ForEach(rows, id: \.0) { r in
                    VStack(alignment: .leading) {
                        Text("Linja \(r.0, specifier: "%.1f")")
                        Text(String(format: "Under: %.2f %%", r.1 * 100))
                        Text(String(format: "Over: %.2f %%", r.2 * 100))
                    }
                }
            }
        }
        .navigationTitle("O/U Poisson")
    }

    func calculate() {
        guard let lam = Double(lambda), let maxV = Int(maxN) else { return }

        let probs = (0...maxV).map { k in
            exp(-lam) * pow(lam, Double(k)) / Double(factorial(k))
        }

        rows = lines.map { line in
            let under = probs.prefix(Int(line)+1).reduce(0,+)
            let over = 1 - under
            return (line, under, over)
        }
    }
}

// ---------------------------------------------------------
// ODDS → IMPLIED
// ---------------------------------------------------------
struct OddsView: View {
    @State private var odds = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Kerroin", text: $odds).keyboardType(.decimalPad)
            Button("Laske") { calc() }
            Text("Implied probability: \(result)")
        }
        .navigationTitle("Odds")
    }

    func calc() {
        guard let o = Double(odds) else { return }
        result = String(format: "%.2f %%", 100 / o)
    }
}

// ---------------------------------------------------------
// KELLY
// ---------------------------------------------------------
struct KellyView: View {
    @State private var bankroll = ""
    @State private var odds = ""
    @State private var prob = ""
    @State private var scale = "1.0"
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Bankroll €", text: $bankroll).keyboardType(.decimalPad)
            TextField("Kerroin", text: $odds).keyboardType(.decimalPad)
            TextField("Todennäköisyys %", text: $prob).keyboardType(.decimalPad)
            TextField("Kelly-skaala", text: $scale).keyboardType(.decimalPad)

            Button("Laske Kelly") { calc() }
            Text(result)
        }
        .navigationTitle("Kelly")
    }

    func calc() {
        guard let br = Double(bankroll),
              let o = Double(odds),
              let p = Double(prob),
              let s = Double(scale) else { return }

        let P = p / 100
        let b = o - 1
        let q = 1 - P

        let k = max(0, (b*P - q) / b)
        let stake = br * k * s

        result = String(format: "Kelly: %.2f %%\nPanos: %.2f €", k*100, stake)
    }
}

// ---------------------------------------------------------
// EV
// ---------------------------------------------------------
struct EVView: View {
    @State private var odds = ""
    @State private var prob = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Kerroin", text: $odds).keyboardType(.decimalPad)
            TextField("Todennäköisyys %", text: $prob).keyboardType(.decimalPad)
            Button("Laske EV") { calc() }
            Text(result)
        }
        .navigationTitle("EV")
    }

    func calc() {
        guard let o = Double(odds), let p = Double(prob) else { return }
        let ev = (p/100 * o - 1) * 100
        result = String(format: "EV: %.2f %%", ev)
    }
}

// ---------------------------------------------------------
// ARBITRAASI
// ---------------------------------------------------------
struct ArbitraasiView: View {
    @State private var o1 = ""
    @State private var o2 = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Kerroin 1", text: $o1).keyboardType(.decimalPad)
            TextField("Kerroin 2", text: $o2).keyboardType(.decimalPad)
            Button("Laske") { calc() }
            Text(result)
        }
        .navigationTitle("Arbitraasi")
    }

    func calc() {
        guard let a = Double(o1), let b = Double(o2) else { return }
        let inv = 1/a + 1/b
        result = String(format: "1/o1 + 1/o2 = %.4f", inv)
    }
}

// ---------------------------------------------------------
// EDGE
// ---------------------------------------------------------
struct EdgeView: View {
    @State private var odds = ""
    @State private var prob = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Kerroin", text: $odds).keyboardType(.decimalPad)
            TextField("Oma todennäköisyys %", text: $prob).keyboardType(.decimalPad)
            Button("Laske Edge") { calc() }
            Text(result)
        }
        .navigationTitle("Edge")
    }

    func calc() {
        guard let o = Double(odds), let p = Double(prob) else { return }
        let implied = 100 / o
        let edge = p - implied
        result = String(format: "Implisiittinen: %.2f %%\nEdge: %.2f %%", implied, edge)
    }
}

// ---------------------------------------------------------
// TEAM XG (SEASON)
// ---------------------------------------------------------
struct TeamXGSeasonView: View {
    @State private var games = ""

    @State private var A_GF = ""
    @State private var A_GA = ""
    @State private var A_SF = ""
    @State private var A_SA = ""
    @State private var A_result = "-"

    @State private var B_GF = ""
    @State private var B_GA = ""
    @State private var B_SF = ""
    @State private var B_SA = ""
    @State private var B_result = "-"

    let leagueGF = 2.8
    let leagueSlot = 11.0

    var body: some View {
        Form {
            Section(header: Text("Pelien määrä")) {
                TextField("Games", text: $games).keyboardType(.decimalPad)
            }

            Section(header: Text("Joukkue A")) {
                TextField("GF total", text: $A_GF).keyboardType(.decimalPad)
                TextField("GA total", text: $A_GA).keyboardType(.decimalPad)
                TextField("Slot For", text: $A_SF).keyboardType(.decimalPad)
                TextField("Slot Against", text: $A_SA).keyboardType(.decimalPad)
                Button("Laske A") { calcA() }
                Text(A_result)
            }

            Section(header: Text("Joukkue B")) {
                TextField("GF total", text: $B_GF).keyboardType(.decimalPad)
                TextField("GA total", text: $B_GA).keyboardType(.decimalPad)
                TextField("Slot For", text: $B_SF).keyboardType(.decimalPad)
                TextField("Slot Against", text: $B_SA).keyboardType(.decimalPad)
                Button("Laske B") { calcB() }
                Text(B_result)
            }
        }
        .navigationTitle("Team xG")
    }

    func attack(_ GF: Double, _ SF: Double) -> Double {
        (GF / leagueGF) * (SF / leagueSlot)
    }

    func defense(_ GA: Double, _ SA: Double) -> Double {
        (GA / leagueGF) * (SA / leagueSlot)
    }

    func calcA() {
        guard let g = Double(games),
              let gf = Double(A_GF),
              let ga = Double(A_GA),
              let sf = Double(A_SF),
              let sa = Double(A_SA) else { return }

        let att = attack(gf/g, sf/g)
        let def = defense(ga/g, sa/g)

        A_result = String(format: "Hyökkäys: %.2f\nPuolustus: %.2f", att, def)
    }

    func calcB() {
        guard let g = Double(games),
              let gf = Double(B_GF),
              let ga = Double(B_GA),
              let sf = Double(B_SF),
              let sa = Double(B_SA) else { return }

        let att = attack(gf/g, sf/g)
        let def = defense(ga/g, sa/g)

        B_result = String(format: "Hyökkäys: %.2f\nPuolustus: %.2f", att, def)
    }
}

// ---------------------------------------------------------
// TOTAL-LINJA VALITSIJA
// ---------------------------------------------------------
struct TotalLineSelectorView: View {
    @State private var l1 = ""; @State private var o1 = ""; @State private var u1 = ""
    @State private var l2 = ""; @State private var o2 = ""; @State private var u2 = ""
    @State private var l3 = ""; @State private var o3 = ""; @State private var u3 = ""
    @State private var result = "-"

    var body: some View {
        Form {
            Section(header: Text("Linja 1")) {
                TextField("Linja", text: $l1)
                TextField("Over", text: $o1)
                TextField("Under", text: $u1)
            }
            Section(header: Text("Linja 2")) {
                TextField("Linja", text: $l2)
                TextField("Over", text: $o2)
                TextField("Under", text: $u2)
            }
            Section(header: Text("Linja 3")) {
                TextField("Linja", text: $l3)
                TextField("Over", text: $o3)
                TextField("Under", text: $u3)
            }

            Button("Valitse päälinja") { calc() }
            Text(result)
        }
        .navigationTitle("Total-linja")
    }

    func calc() {
        guard let L1 = Double(l1), let O1 = Double(o1), let U1 = Double(u1),
              let L2 = Double(l2), let O2 = Double(o2), let U2 = Double(u2),
              let L3 = Double(l3), let O3 = Double(o3), let U3 = Double(u3)
        else { return }

        let diffs = [
            (abs(O1-U1), L1),
            (abs(O2-U2), L2),
            (abs(O3-U3), L3)
        ].sorted { $0.0 < $1.0 }

        result = "Päälinja: \(diffs[0].1)"
    }
}

// ---------------------------------------------------------
// NO-VIG 2-WAY
// ---------------------------------------------------------
struct NoVig2WayView: View {
    @State private var o1 = ""
    @State private var o2 = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("Kerroin 1", text: $o1).keyboardType(.decimalPad)
            TextField("Kerroin 2", text: $o2).keyboardType(.decimalPad)
            Button("Laske") { calc() }
            Text(result)
        }
        .navigationTitle("No-Vig 2-way")
    }

    func calc() {
        guard let a = Double(o1), let b = Double(o2) else { return }

        let p1 = 100 / a
        let p2 = 100 / b
        let total = p1 + p2

        let f1 = p1 / total * 100
        let f2 = p2 / total * 100

        result = String(format: "No-vig: %.2f %% / %.2f %%", f1, f2)
    }
}

// ---------------------------------------------------------
// NO-VIG 1X2
// ---------------------------------------------------------
struct NoVig1X2View: View {
    @State private var o1 = ""
    @State private var oX = ""
    @State private var o2 = ""
    @State private var result = "-"

    var body: some View {
        Form {
            TextField("1 kerroin", text: $o1).keyboardType(.decimalPad)
            TextField("X kerroin", text: $oX).keyboardType(.decimalPad)
            TextField("2 kerroin", text: $o2).keyboardType(.decimalPad)

            Button("Laske") { calc() }
            Text(result)
        }
        .navigationTitle("1X2 No-Vig")
    }

    func calc() {
        guard let a = Double(o1), let x = Double(oX), let b = Double(o2) else { return }

        let p1 = 100 / a
        let pX = 100 / x
        let p2 = 100 / b

        let total = p1 + pX + p2
        let margin = total - 100

        let f1 = p1 / total * 100
        let fX = pX / total * 100
        let f2 = p2 / total * 100

        result = String(format:
            "No-vig:\n1 %.2f %%\nX %.2f %%\n2 %.2f %%\nMarginaali: %.2f %%",
            f1, fX, f2, margin
        )
    }
}
