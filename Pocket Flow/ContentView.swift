//
//  ContentView.swift
//  Pocket Flow
//
//  Created by Atalay Okun on 8.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var expenses: [Expense] = Expense.sampleData
    @State private var showAddSheet: Bool = false
    
    private var calendar: Calendar { Calendar.current }
    
    private var currentMonthExpenses: [Expense] {
        let now = Date()
        return expenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
    
    private var monthTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var recentExpenses: [Expense] {
        let sorted = expenses.sorted { $0.date > $1.date }
        return Array(sorted.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.green.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // ÜST KUTU - BU AY
                    NavigationLink {
                        MonthlyDetailView(expenses: currentMonthExpenses)
                    } label: {
                        MonthlySummaryBox(
                            total: monthTotal,
                            count: currentMonthExpenses.count
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // ORTA KUTU - SON HARCAMALAR
                    RecentExpensesBox(expenses: recentExpenses)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                // ALTTA + BUTONU
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
            .sheet(isPresented: $showAddSheet) {
                AddExpenseSheet(expenses: $expenses)
            }
        }
    }
}

struct MonthlySummaryBox: View {
    let total: Double
    let count: Int
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
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
            
            Text("\(count) expenses this month")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.9))
            
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
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
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
            
            // Başlık YEŞİL
            Text("Recent Expenses")
                .font(.headline)
                .foregroundColor(.green)
            
            if expenses.isEmpty {
                // Boş durum SİYAH
                Text("No expenses yet. Tap + to add your first one.")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
            } else {
                ForEach(expenses) { expense in
                    HStack(spacing: 12) {
                        
                        // Emoji
                        Text(expense.category.emoji)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            // ✅ HARÇAMA ADI SİMSİYAH
                            Text(expense.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.black)
                            
                            // ✅ KATEGORİ + TARİH DE SİMSİYAH
                            HStack(spacing: 6) {
                                Text(expense.category.title)
                                Text("·")
                                Text(Self.dateFormatter.string(from: expense.date))
                            }
                            .font(.caption)
                            .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // ✅ TUTAR YEŞİL
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
        .background(Color.white)   // ✅ BEYAZ ZEMİN
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}

struct MonthlyDetailView: View {
    let expenses: [Expense]
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    private var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
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
                if expenses.isEmpty {
                    Text("No expenses recorded for this month yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(expenses.sorted { $0.date > $1.date }) { expense in
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
                }
            }
        }
        .navigationTitle("This Month")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var expenses: [Expense]
    
    @State private var selectedCategory: ExpenseCategory? = .food
    @State private var amountText: String = ""
    @State private var title: String = ""
    
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
                    Button("Cancel") {
                        dismiss()
                    }
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
            date: Date()
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
        case .coffee: return Color(red: 0.18, green: 0.55, blue: 0.34) // yeşile yakın
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



#Preview {
    ContentView()
}
