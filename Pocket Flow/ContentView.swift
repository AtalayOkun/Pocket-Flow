//
//  ContentView.swift
//  Pocket Flow
//
//  Created by Atalay Okun on 8.12.2025.
//

import SwiftUI
import Foundation

// MARK: - Models

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case coffee
    case food
    case transport
    case entertainment
    case shopping
    case other
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .coffee: return "Coffee"
        case .food: return "Food"
        case .transport: return "Transport"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .other: return "Other"
        }
    }
    
    var emoji: String {
        switch self {
        case .coffee: return "☕️"
        case .food: return "🍔"
        case .transport: return "🚗"
        case .entertainment: return "🎮"
        case .shopping: return "🛍️"
        case .other: return "💸"
        }
    }
}

struct Expense: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let isUnnecessary: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: ExpenseCategory,
        date: Date = Date(),
        isUnnecessary: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.isUnnecessary = isUnnecessary
    }
    
    /// Demo için örnek veriler
    static let sampleData: [Expense] = {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: now)!
        
        return [
            Expense(title: "Starbucks Latte", amount: 95, category: .coffee, date: now, isUnnecessary: true),
            Expense(title: "Burger King", amount: 160, category: .food, date: now, isUnnecessary: true),
            Expense(title: "Taxi Ride", amount: 120, category: .transport, date: yesterday, isUnnecessary: false),
            Expense(title: "Steam Game", amount: 349, category: .entertainment, date: threeDaysAgo, isUnnecessary: true),
            Expense(title: "Online Shopping", amount: 420, category: .shopping, date: sixDaysAgo, isUnnecessary: true),
            Expense(title: "Water", amount: 80, category: .other, date: sixDaysAgo, isUnnecessary: false)
        ]
    }()
}

struct Subscription: Identifiable, Codable {
    let id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var billingDay: Int      // her ayın kaçıncı günü
    var isActive: Bool
    var lastChargedDate: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        category: ExpenseCategory,
        billingDay: Int,
        isActive: Bool = true,
        lastChargedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.billingDay = billingDay
        self.isActive = isActive
        self.lastChargedDate = lastChargedDate
    }
    
    static let sampleData: [Subscription] = [
        Subscription(name: "Netflix", amount: 119.99, category: .entertainment, billingDay: 5),
        Subscription(name: "Spotify", amount: 59.99, category: .entertainment, billingDay: 12),
        Subscription(name: "iCloud", amount: 19.99, category: .other, billingDay: 1)
    ]
}

// MARK: - ContentView

struct ContentView: View {
    // State
    @State private var expenses: [Expense] = Expense.sampleData
    @State private var subscriptions: [Subscription] = Subscription.sampleData
    
    @State private var showAddSheet = false
    @State private var showSubscriptions = false
    @State private var showUnnecessaryReport = false
    @State private var showCategoryAnalysis = false
    @State private var showLimitSheet = false
    
    @State private var monthlyLimit: Double = 5000   // varsayılan limit
    
    private var calendar: Calendar { Calendar.current }
    
    // MARK: - Hesaplamalar
    
    private var currentMonthExpenses: [Expense] {
        let now = Date()
        return expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
    
    private var monthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var monthUnnecessaryTotal: Double {
        currentMonthExpenses
            .filter { $0.isUnnecessary }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var limitProgress: Double {
        guard monthlyLimit > 0 else { return 0 }
        return min(monthTotal / monthlyLimit, 1.0)
    }
    
    private var recentExpenses: [Expense] {
        let sorted = expenses.sorted { $0.date > $1.date }
        return Array(sorted.prefix(5))
    }
    
    // Streak: bugünden geriye doğru kaç gün üst üste harcama girilmiş
    private var currentStreak: Int {
        let dateSet = Set(expenses.map { calendar.startOfDay(for: $0.date) })
        guard !dateSet.isEmpty else { return 0 }
        
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        
        while dateSet.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
    
    // Kategori toplamları (bu ay)
    private var categoryTotalsThisMonth: [(ExpenseCategory, Double)] {
        var dict: [ExpenseCategory: Double] = [:]
        for expense in currentMonthExpenses {
            dict[expense.category, default: 0] += expense.amount
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.green.opacity(0.05).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // ÜST KUTU
                    NavigationLink {
                        MonthlyDetailView(expenses: $expenses)
                    } label: {
                        MonthlySummaryBox(
                            total: monthTotal,
                            unnecessary: monthUnnecessaryTotal,
                            limit: monthlyLimit,
                            progress: limitProgress,
                            streak: currentStreak
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // ALT KUTU
                    RecentExpensesBox(expenses: recentExpenses)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                // + BUTONU
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 64, height: 64)
                                    .shadow(radius: 8)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("SpinSpend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Abonelikler butonu
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSubscriptions = true
                    } label: {
                        Image(systemName: "repeat")
                            .foregroundColor(.green)
                    }
                }
                
                // Menü: analiz + limit + gereksiz rapor
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCategoryAnalysis = true
                        } label: {
                            Label("Category Analysis", systemImage: "chart.bar.fill")
                        }
                        Button {
                            showUnnecessaryReport = true
                        } label: {
                            Label("Unnecessary Report", systemImage: "exclamationmark.triangle.fill")
                        }
                        Button {
                            showLimitSheet = true
                        } label: {
                            Label("Set Monthly Limit", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            // Sheet’ler
            .sheet(isPresented: $showAddSheet) {
                AddExpenseSheet(expenses: $expenses)
            }
            .sheet(isPresented: $showSubscriptions) {
                SubscriptionListView(
                    subscriptions: $subscriptions,
                    onApplyDueSubscriptions: applyDueSubscriptions
                )
            }
            .sheet(isPresented: $showUnnecessaryReport) {
                UnnecessaryReportView(
                    monthTotal: monthTotal,
                    unnecessaryTotal: monthUnnecessaryTotal
                )
            }
            .sheet(isPresented: $showCategoryAnalysis) {
                CategoryAnalysisView(pairs: categoryTotalsThisMonth)
            }
            .sheet(isPresented: $showLimitSheet) {
                LimitSettingsSheet(limit: $monthlyLimit)
            }
            .onAppear {
                applyDueSubscriptions()
            }
        }
    }
    
    // MARK: - Abonelikleri otomatik düşürme
    
    private func applyDueSubscriptions() {
        let now = Date()
        
        for index in subscriptions.indices {
            guard subscriptions[index].isActive else { continue }
            let billingDay = subscriptions[index].billingDay
            
            if let billingDateThisMonth = calendar.date(
                bySetting: .day,
                value: billingDay,
                of: now
            ) {
                // Bu ay zaten işlenmiş mi?
                if let last = subscriptions[index].lastChargedDate,
                   calendar.isDate(last, equalTo: now, toGranularity: .month) {
                    continue
                }
                
                // Fatura günü bugün veya geçtiyse
                if billingDateThisMonth <= now {
                    let expense = Expense(
                        title: subscriptions[index].name,
                        amount: subscriptions[index].amount,
                        category: subscriptions[index].category,
                        date: billingDateThisMonth,
                        isUnnecessary: false
                    )
                    expenses.append(expense)
                    subscriptions[index].lastChargedDate = now
                }
            }
        }
    }
}

// MARK: - Views

struct MonthlySummaryBox: View {
    let total: Double
    let unnecessary: Double
    let limit: Double
    let progress: Double      // 0...1
    let streak: Int
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }
    
    private var progressText: String {
        guard limit > 0 else { return "No limit set" }
        let percent = Int(progress * 100)
        return "\(percent)% of your ₺\(Int(limit)) limit"
    }
    
    private var streakText: String {
        if streak == 0 { return "No streak yet" }
        if streak == 1 { return "1 day streak" }
        return "\(streak) day streak 🔥"
    }
    
    private var unnecessaryComment: String {
        if unnecessary == 0 {
            return "No unnecessary spending so far 👌"
        } else if unnecessary < 500 {
            return "Small unnecessary treats, not bad 😏"
        } else if unnecessary < 2000 {
            return "Your wallet is getting warm 🔥"
        } else {
            return "You burned a serious amount this month 💀"
        }
    }
    
    private var progressColor: Color {
        guard limit > 0 else { return .white }
        let ratio = total / limit
        switch ratio {
        case ..<0.5: return .white
        case ..<0.9: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthName.capitalized)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("This Month's Spending")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("₺ \(Int(total))")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            // Limit + progress bar
            if limit > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(progressText)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(progressColor)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            } else {
                Text("No monthly limit set")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Gereksiz + streak
            VStack(alignment: .leading, spacing: 4) {
                Text("Unnecessary this month: ₺\(Int(unnecessary))")
                    .font(.footnote)
                    .foregroundColor(.white)
                
                Text(unnecessaryComment)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(streakText)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 4)
            
            Spacer()
            
            HStack {
                Text("Tap to see details")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.green, Color.green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 6)
    }
}

struct RecentExpensesBox: View {
    let expenses: [Expense]
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.headline)
                .foregroundColor(.green)
            
            if expenses.isEmpty {
                Text("No expenses yet. Tap + to add your first one.")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
            } else {
                ForEach(expenses) { expense in
                    HStack(spacing: 12) {
                        Text(expense.category.emoji)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 6) {
                                Text(expense.category.title)
                                Text("·")
                                Text(Self.dateFormatter.string(from: expense.date))
                            }
                            .font(.caption)
                            .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("₺ \(Int(expense.amount))")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 6)
                    
                    if expense.id != expenses.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}

// Aylık detay

struct MonthlyDetailView: View {
    @Binding var expenses: [Expense]
    
    private let calendar = Calendar.current
    
    // Sadece bu ayın harcamaları, tarihe göre sıralı
    private var monthExpenses: [Expense] {
        let now = Date()
        return expenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }
    
    private var total: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Total this month")
                    Spacer()
                    Text("₺ \(Int(total))")
                        .font(.headline.bold())
                        .foregroundColor(.green)
                }
            }
            
            Section("All expenses this month") {
                if monthExpenses.isEmpty {
                    Text("No expenses recorded for this month yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(monthExpenses) { expense in
                        HStack(spacing: 12) {
                            Text(expense.category.emoji)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.title)
                                    .font(.subheadline.weight(.semibold))
                                
                                HStack(spacing: 6) {
                                    Text(expense.category.title)
                                    Text("·")
                                    Text(Self.dateFormatter.string(from: expense.date))
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("₺ \(Int(expense.amount))")
                                .font(.subheadline.bold())
                        }
                        .padding(.vertical, 2)
                    }
                    // 👉 iPhone'daki gibi sola kaydır → Delete
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("This Month")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func delete(at offsets: IndexSet) {
        // List'te görünen dizide silinecek satırların id’lerini bul
        let idsToDelete = offsets.map { monthExpenses[$0].id }
        
        // Asıl kaynak dizi olan expenses içinden bu id’leri sil
        expenses.removeAll { exp in
            idsToDelete.contains(exp.id)
        }
    }
}

// Yeni harcama sheet + çark

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var expenses: [Expense]
    
    @State private var selectedCategory: ExpenseCategory? = .food
    @State private var amountText: String = ""
    @State private var title: String = ""
    @State private var isUnnecessary: Bool = false
    
    private var amountValue: Double? {
        let text = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(text)
    }
    
    private var canSave: Bool {
        selectedCategory != nil && amountValue != nil && amountValue! > 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                CategoryWheel(selectedCategory: $selectedCategory)
                    .frame(height: 260)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amount")
                        .font(.subheadline.weight(.medium))
                    
                    HStack {
                        Text("₺")
                            .font(.title3.bold())
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (optional)")
                        .font(.subheadline.weight(.medium))
                    
                    TextField("e.g. Starbucks, Uber, Steam...", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                Toggle(isOn: $isUnnecessary) {
                    Text("Mark as unnecessary")
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: saveExpense) {
                    Text("Save Expense")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.green : Color.green.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canSave)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let category = selectedCategory,
              let amount = amountValue,
              amount > 0 else { return }
        
        let finalTitle: String
        if !title.trimmingCharacters(in: .whitespaces).isEmpty {
            finalTitle = title.trimmingCharacters(in: .whitespaces)
        } else {
            finalTitle = category.title
        }
        
        let newExpense = Expense(
            title: finalTitle,
            amount: amount,
            category: category,
            date: Date(),
            isUnnecessary: isUnnecessary
        )
        
        expenses.append(newExpense)
        dismiss()
    }
}

struct CategoryWheel: View {
    @Binding var selectedCategory: ExpenseCategory?
    
    private let radius: CGFloat = 90
    
    private func color(for category: ExpenseCategory) -> Color {
        switch category {
        case .coffee: return Color.green
        case .food: return Color.orange
        case .transport: return Color.blue
        case .entertainment: return Color.purple
        case .shopping: return Color.pink
        case .other: return Color.gray
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 4)
                .frame(width: radius * 2 + 40, height: radius * 2 + 40)
            
            let categories = ExpenseCategory.allCases
            ForEach(Array(categories.enumerated()), id: \.1.id) { index, category in
                let angle = Double(index) / Double(categories.count) * 2 * Double.pi
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = category
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(category.emoji)
                            .font(.title2)
                        Text(category.title)
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(
                        Circle()
                            .fill(color(for: category).opacity(
                                selectedCategory == category ? 1.0 : 0.65
                            ))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(selectedCategory == category ? 1 : 0),
                                    lineWidth: 2)
                    )
                    .shadow(radius: 4)
                }
                .offset(x: x, y: y)
            }
            
            if let selected = selectedCategory {
                VStack(spacing: 6) {
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(selected.emoji)
                        .font(.largeTitle)
                    Text(selected.title)
                        .font(.headline)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 5)
            } else {
                Text("Choose a category")
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 5)
            }
        }
    }
}

// Abonelikler

struct SubscriptionListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var subscriptions: [Subscription]
    
    var onApplyDueSubscriptions: () -> Void
    
    @State private var showAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                if subscriptions.isEmpty {
                    Text("No subscriptions yet. Add your Netflix, Spotify, etc.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach($subscriptions) { $sub in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sub.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(sub.category.title) · every month on day \(sub.billingDay)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₺ \(Int(sub.amount))")
                                    .font(.subheadline.bold())
                                Toggle("", isOn: $sub.isActive)
                                    .labelsHidden()
                            }
                        }
                    }
                    .onDelete { indexSet in
                        subscriptions.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSubscriptionSheet(subscriptions: $subscriptions, onDone: {
                    onApplyDueSubscriptions()
                })
            }
        }
    }
}

struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var subscriptions: [Subscription]
    
    var onDone: () -> Void
    
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .entertainment
    @State private var billingDay: Int = 1
    
    private var amountValue: Double? {
        let t = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(t)
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountValue != nil &&
        amountValue! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    TextField("Name (Netflix, Spotify...)", text: $name)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.title).tag(cat)
                        }
                    }
                }
                
                Section("Billing Day") {
                    Picker("Day of month", selection: $billingDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }
            }
            .navigationTitle("New Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func save() {
        guard let amount = amountValue, amount > 0 else { return }
        
        let sub = Subscription(
            name: name.trimmingCharacters(in: .whitespaces),
            amount: amount,
            category: category,
            billingDay: billingDay,
            isActive: true,
            lastChargedDate: nil
        )
        
        subscriptions.append(sub)
        onDone()
        dismiss()
    }
}

// Gereksiz raporu

struct UnnecessaryReportView: View {
    let monthTotal: Double
    let unnecessaryTotal: Double
    
    private var ratioText: String {
        guard monthTotal > 0 else { return "No spending recorded this month." }
        let ratio = unnecessaryTotal / monthTotal
        let percent = Int(ratio * 100)
        return "\(percent)% of your spending this month was unnecessary."
    }
    
    private var comment: String {
        guard monthTotal > 0 else { return "Start recording your expenses to see a report." }
        if unnecessaryTotal == 0 {
            return "Pure discipline. Your wallet is proud of you. 🧠"
        } else if unnecessaryTotal < 500 {
            return "Tiny treats, you’re mostly under control. 😏"
        } else if unnecessaryTotal < 2000 {
            return "You’re enjoying life, but your wallet feels it. 🔥"
        } else {
            return "You’re funding the economy alone this month. 💀"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Unnecessary Spending")
                    .font(.title2.bold())
                
                Text("Total unnecessary this month:")
                    .font(.subheadline)
                
                Text("₺ \(Int(unnecessaryTotal))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                
                Text(ratioText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(comment)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Unnecessary Report")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Kategori analizi

struct CategoryAnalysisView: View {
    let pairs: [(ExpenseCategory, Double)]
    
    private var total: Double {
        pairs.reduce(0) { $0 + $1.1 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Category Analysis")
                    .font(.title2.bold())
                
                if pairs.isEmpty {
                    Text("No expenses this month.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        Section("By Category") {
                            ForEach(pairs, id: \.0.id) { category, value in
                                let percent = total > 0 ? Int((value / total) * 100) : 0
                                HStack {
                                    Text("\(category.emoji) \(category.title)")
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("₺ \(Int(value))")
                                            .font(.subheadline.bold())
                                        Text("\(percent)%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Category Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Limit ayarı

struct LimitSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var limit: Double
    
    @State private var tempText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Monthly Limit") {
                    TextField("Amount", text: $tempText)
                        .keyboardType(.decimalPad)
                }
                
                if let value = Double(tempText.replacingOccurrences(of: ",", with: ".")),
                   value > 0 {
                    Text("Current: ₺\(Int(value))")
                        .foregroundColor(.green)
                } else {
                    Text("Enter a positive number")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Set Monthly Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(tempText.replacingOccurrences(of: ",", with: ".")),
                           v > 0 {
                            limit = v
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempText = String(Int(limit))
            }
        }
    }
}

// Preview

#Preview {
    ContentView()
}
