# frozen_string_literal: true

namespace :demo do
  desc "Seed the database with demo data (idempotent, safe to re-run)"
  task seed: :environment do
    puts "=== Seeding demo data ==="

    password = "Tatl-Demo-2026!"

    # ─── Users (one per role) ───────────────────────────────────────────
    puts "\n--- Users ---"

    users = {
      admin: {
        email: "admin@tatl.demo",
        first_name: "Dana",
        last_name: "Morales",
        role: :admin
      },
      treasurer: {
        email: "treasurer@tatl.demo",
        first_name: "Pat",
        last_name: "Nguyen",
        role: :treasurer
      },
      board: {
        email: "board@tatl.demo",
        first_name: "Jordan",
        last_name: "Whitfield",
        role: :board
      },
      resident_owner: {
        email: "owner@tatl.demo",
        first_name: "Casey",
        last_name: "Brooks",
        role: :resident
      },
      resident_tenant: {
        email: "tenant@tatl.demo",
        first_name: "Riley",
        last_name: "Chen",
        role: :resident
      },
      resident_second: {
        email: "resident@tatl.demo",
        first_name: "Morgan",
        last_name: "Adler",
        role: :resident
      }
    }

    created_users = {}

    users.each do |key, attrs|
      user = User.find_or_initialize_by(email: attrs[:email])
      user.assign_attributes(
        first_name: attrs[:first_name],
        last_name: attrs[:last_name],
        role: attrs[:role],
        password: password,
        password_confirmation: password,
        confirmed_at: Time.current
      )
      user.save!
      created_users[key] = user
      puts "  #{user.role.ljust(10)} #{user.full_name.ljust(20)} #{user.email}"
    end

    # ─── Properties ─────────────────────────────────────────────────────
    puts "\n--- Properties ---"

    properties_data = [
      { name: "101 Oakridge Lane",  lot_number: "LOT-001", property_type: :single_family, street_address: "101 Oakridge Ln",  city: "Maplewood", state: "NC", zip: "28701" },
      { name: "102 Oakridge Lane",  lot_number: "LOT-002", property_type: :single_family, street_address: "102 Oakridge Ln",  city: "Maplewood", state: "NC", zip: "28701" },
      { name: "103 Oakridge Lane",  lot_number: "LOT-003", property_type: :townhome,      street_address: "103 Oakridge Ln",  city: "Maplewood", state: "NC", zip: "28701" },
      { name: "104 Oakridge Lane",  lot_number: "LOT-004", property_type: :townhome,      street_address: "104 Oakridge Ln",  city: "Maplewood", state: "NC", zip: "28701" },
      { name: "201 Maple Drive",    lot_number: "LOT-005", property_type: :condo,          street_address: "201 Maple Dr",     city: "Maplewood", state: "NC", zip: "28701" },
      { name: "202 Maple Drive",    lot_number: "LOT-006", property_type: :condo,          street_address: "202 Maple Dr",     city: "Maplewood", state: "NC", zip: "28701" },
      { name: "301 Birch Court",    lot_number: "LOT-007", property_type: :single_family, street_address: "301 Birch Ct",     city: "Maplewood", state: "NC", zip: "28701" },
      { name: "Lot 8 – Undeveloped", lot_number: "LOT-008", property_type: :lot,           street_address: nil,                city: "Maplewood", state: "NC", zip: "28701", notes: "Vacant lot, approved for single-family construction." }
    ]

    created_properties = {}

    properties_data.each do |attrs|
      prop = Property.find_or_initialize_by(lot_number: attrs[:lot_number])
      prop.assign_attributes(attrs)
      prop.save!
      created_properties[attrs[:lot_number]] = prop
      puts "  #{prop.lot_number}  #{prop.name} (#{prop.property_type})"
    end

    # ─── Memberships ────────────────────────────────────────────────────
    puts "\n--- Memberships ---"

    membership_data = [
      { user: :admin,           property: "LOT-001", role: :owner,    started_on: Date.new(2023, 3, 1) },
      { user: :treasurer,       property: "LOT-002", role: :owner,    started_on: Date.new(2022, 6, 15) },
      { user: :board,           property: "LOT-003", role: :owner,    started_on: Date.new(2024, 1, 10) },
      { user: :resident_owner,  property: "LOT-004", role: :owner,    started_on: Date.new(2023, 9, 1) },
      { user: :resident_tenant, property: "LOT-005", role: :tenant,   started_on: Date.new(2025, 4, 1) },
      { user: :resident_second, property: "LOT-006", role: :owner,    started_on: Date.new(2024, 7, 1) },
      { user: :resident_second, property: "LOT-007", role: :resident, started_on: Date.new(2025, 1, 15) }
    ]

    membership_data.each do |attrs|
      user = created_users[attrs[:user]]
      prop = created_properties[attrs[:property]]
      mem = Membership.find_or_initialize_by(user: user, property: prop, ended_on: nil)
      mem.assign_attributes(role: attrs[:role], started_on: attrs[:started_on])
      mem.save!
      puts "  #{user.full_name.ljust(20)} → #{prop.name.ljust(22)} (#{mem.role})"
    end

    # ─── Accounts ───────────────────────────────────────────────────────
    puts "\n--- Accounts ---"

    accounts_data = [
      { name: "Operating Fund",       account_type: :operating, description: "Day-to-day HOA operating expenses." },
      { name: "Reserve Fund",         account_type: :reserve,   description: "Long-term capital reserves for major repairs." },
      { name: "Dues Income",          account_type: :income,    description: "Revenue from quarterly homeowner dues." },
      { name: "Maintenance Expense",  account_type: :expense,   description: "Grounds keeping, repairs, and general maintenance." },
      { name: "Landscaping Expense",  account_type: :expense,   description: "Lawn care, tree trimming, and seasonal planting." },
      { name: "Insurance Expense",    account_type: :expense,   description: "Property and liability insurance premiums." },
      { name: "Utilities Expense",    account_type: :expense,   description: "Common area water, electric, and internet." }
    ]

    created_accounts = {}

    accounts_data.each do |attrs|
      acct = Account.find_or_initialize_by(name: attrs[:name])
      acct.assign_attributes(attrs)
      acct.save!
      created_accounts[attrs[:name]] = acct
      puts "  #{acct.account_type.ljust(10)} #{acct.name}"
    end

    # ─── Budget Lines (current year) ────────────────────────────────────
    puts "\n--- Budget Lines (#{Date.current.year}) ---"

    budget_data = [
      { account: "Operating Fund",      amount: 24_000.00, description: "Annual operating budget" },
      { account: "Reserve Fund",        amount: 12_000.00, description: "Annual reserve contribution" },
      { account: "Dues Income",         amount: 33_600.00, description: "Projected dues revenue (8 lots × $4,200)" },
      { account: "Maintenance Expense", amount: 8_000.00,  description: "General maintenance budget" },
      { account: "Landscaping Expense", amount: 6_000.00,  description: "Landscaping contract" },
      { account: "Insurance Expense",   amount: 4_800.00,  description: "Annual insurance premium" },
      { account: "Utilities Expense",   amount: 3_600.00,  description: "Common area utilities" }
    ]

    year = Date.current.year

    budget_data.each do |attrs|
      acct = created_accounts[attrs[:account]]
      bl = BudgetLine.find_or_initialize_by(account: acct, fiscal_year: year)
      bl.assign_attributes(amount: Money.new((attrs[:amount] * 100).to_i, "USD"), description: attrs[:description])
      bl.save!
      puts "  #{acct.name.ljust(25)} $#{"%.2f" % attrs[:amount]}"
    end

    # ─── Transactions ───────────────────────────────────────────────────
    puts "\n--- Transactions ---"

    treasurer = created_users[:treasurer]

    transactions_data = [
      { account: "Dues Income",         amount:  4_200.00, transacted_on: Date.new(year, 1, 5),  memo: "Q1 dues payment – LOT-001" },
      { account: "Dues Income",         amount:  4_200.00, transacted_on: Date.new(year, 1, 8),  memo: "Q1 dues payment – LOT-002" },
      { account: "Dues Income",         amount:  4_200.00, transacted_on: Date.new(year, 1, 12), memo: "Q1 dues payment – LOT-003" },
      { account: "Dues Income",         amount:  2_100.00, transacted_on: Date.new(year, 2, 3),  memo: "Partial Q1 dues – LOT-004" },
      { account: "Dues Income",         amount:  4_200.00, transacted_on: Date.new(year, 1, 15), memo: "Q1 dues payment – LOT-005" },
      { account: "Dues Income",         amount:  4_200.00, transacted_on: Date.new(year, 1, 20), memo: "Q1 dues payment – LOT-006" },
      { account: "Maintenance Expense", amount: -1_250.00, transacted_on: Date.new(year, 1, 22), memo: "Roof repair – common area pavilion" },
      { account: "Landscaping Expense", amount: -1_500.00, transacted_on: Date.new(year, 2, 1),  memo: "February landscaping contract" },
      { account: "Landscaping Expense", amount: -1_500.00, transacted_on: Date.new(year, 3, 1),  memo: "March landscaping contract" },
      { account: "Insurance Expense",   amount: -4_800.00, transacted_on: Date.new(year, 1, 10), memo: "Annual insurance premium" },
      { account: "Utilities Expense",   amount:   -320.00, transacted_on: Date.new(year, 1, 31), memo: "January utilities" },
      { account: "Utilities Expense",   amount:   -295.00, transacted_on: Date.new(year, 2, 28), memo: "February utilities" },
      { account: "Utilities Expense",   amount:   -310.00, transacted_on: Date.new(year, 3, 31), memo: "March utilities" },
      { account: "Reserve Fund",        amount:  3_000.00, transacted_on: Date.new(year, 3, 31), memo: "Q1 reserve transfer" },
      { account: "Operating Fund",      amount:  6_000.00, transacted_on: Date.new(year, 1, 2),  memo: "Q1 operating fund deposit" }
    ]

    created_transactions = {}

    transactions_data.each do |attrs|
      acct = created_accounts[attrs[:account]]
      txn = Transaction.find_or_initialize_by(
        account: acct,
        transacted_on: attrs[:transacted_on],
        memo: attrs[:memo]
      )
      txn.assign_attributes(
        amount: Money.new((attrs[:amount] * 100).to_i, "USD"),
        recorded_by: treasurer
      )
      txn.save!
      created_transactions[attrs[:memo]] = txn
      sign = attrs[:amount].negative? ? "" : "+"
      puts "  #{attrs[:transacted_on]}  #{sign}$#{"%.2f" % attrs[:amount].abs}  #{attrs[:memo]}"
    end

    # ─── Dues Assessments ───────────────────────────────────────────────
    puts "\n--- Dues Assessments ---"

    q1_start = Date.new(year, 1, 1)
    q1_end   = Date.new(year, 3, 31)
    q1_due   = Date.new(year, 1, 15)
    q2_start = Date.new(year, 4, 1)
    q2_end   = Date.new(year, 6, 30)
    q2_due   = Date.new(year, 4, 15)

    assessment_data = [
      { property: "LOT-001", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :paid,    description: "Q1 #{year} Dues" },
      { property: "LOT-002", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :paid,    description: "Q1 #{year} Dues" },
      { property: "LOT-003", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :paid,    description: "Q1 #{year} Dues" },
      { property: "LOT-004", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :partial, description: "Q1 #{year} Dues" },
      { property: "LOT-005", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :paid,    description: "Q1 #{year} Dues" },
      { property: "LOT-006", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :paid,    description: "Q1 #{year} Dues" },
      { property: "LOT-007", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :overdue, description: "Q1 #{year} Dues" },
      { property: "LOT-008", period_start: q1_start, period_end: q1_end, due_date: q1_due, amount: 4_200.00, status: :overdue, description: "Q1 #{year} Dues" },
      { property: "LOT-001", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-002", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-003", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-004", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-005", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-006", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-007", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" },
      { property: "LOT-008", period_start: q2_start, period_end: q2_end, due_date: q2_due, amount: 4_200.00, status: :open,    description: "Q2 #{year} Dues" }
    ]

    created_assessments = {}

    assessment_data.each do |attrs|
      prop = created_properties[attrs[:property]]
      assessment = DuesAssessment.find_or_initialize_by(
        property: prop,
        period_start: attrs[:period_start],
        period_end: attrs[:period_end]
      )
      assessment.assign_attributes(
        due_date: attrs[:due_date],
        amount: Money.new((attrs[:amount] * 100).to_i, "USD"),
        status: attrs[:status],
        description: attrs[:description]
      )
      assessment.save!
      created_assessments["#{attrs[:property]}-#{attrs[:period_start]}"] = assessment
      puts "  #{prop.lot_number}  #{attrs[:description].ljust(16)} #{attrs[:status].to_s.ljust(8)} $#{"%.2f" % attrs[:amount]}"
    end

    # ─── Dues Payments ──────────────────────────────────────────────────
    puts "\n--- Dues Payments ---"

    payments_data = [
      { assessment: "LOT-001-#{q1_start}", amount: 4_200.00, paid_on: Date.new(year, 1, 5),  reference: "CHK-1001" },
      { assessment: "LOT-002-#{q1_start}", amount: 4_200.00, paid_on: Date.new(year, 1, 8),  reference: "CHK-1002" },
      { assessment: "LOT-003-#{q1_start}", amount: 4_200.00, paid_on: Date.new(year, 1, 12), reference: "ACH-2001" },
      { assessment: "LOT-004-#{q1_start}", amount: 2_100.00, paid_on: Date.new(year, 2, 3),  reference: "CHK-1003" },
      { assessment: "LOT-005-#{q1_start}", amount: 4_200.00, paid_on: Date.new(year, 1, 15), reference: "ACH-2002" },
      { assessment: "LOT-006-#{q1_start}", amount: 4_200.00, paid_on: Date.new(year, 1, 20), reference: "ACH-2003" }
    ]

    payments_data.each do |attrs|
      assessment = created_assessments[attrs[:assessment]]
      payment = DuesPayment.find_or_initialize_by(
        dues_assessment: assessment,
        paid_on: attrs[:paid_on],
        reference: attrs[:reference]
      )
      payment.assign_attributes(
        amount: Money.new((attrs[:amount] * 100).to_i, "USD")
      )
      payment.save!
      puts "  #{attrs[:reference].ljust(10)} $#{"%.2f" % attrs[:amount]}  on #{attrs[:paid_on]}"
    end

    # ─── Summary ────────────────────────────────────────────────────────
    puts "\n#{"=" * 60}"
    puts "  Demo data seeded successfully!"
    puts "#{"=" * 60}"
    puts "\n  Test accounts (password for all: #{password}):\n\n"
    puts "  %-12s %-22s %s" % ["ROLE", "NAME", "EMAIL"]
    puts "  #{"-" * 56}"
    created_users.each_value do |u|
      puts "  %-12s %-22s %s" % [u.role, u.full_name, u.email]
    end
    puts "\n  Properties: #{Property.count}"
    puts "  Memberships: #{Membership.count}"
    puts "  Accounts: #{Account.count}"
    puts "  Transactions: #{Transaction.count}"
    puts "  Dues Assessments: #{DuesAssessment.count}"
    puts "  Dues Payments: #{DuesPayment.count}"
    puts "  Budget Lines: #{BudgetLine.count}"
    puts ""
  end

  desc "Remove all demo data (users with @tatl.demo emails and associated records)"
  task teardown: :environment do
    puts "=== Removing demo data ==="

    demo_users = User.where("email LIKE ?", "%@tatl.demo")
    demo_emails = demo_users.pluck(:email)

    if demo_emails.empty?
      puts "  No demo users found. Nothing to remove."
      next
    end

    puts "  Found #{demo_emails.size} demo users: #{demo_emails.join(", ")}"

    ActiveRecord::Base.transaction do
      Transaction.where(recorded_by: demo_users).find_each do |txn|
        txn.file.purge if txn.file.attached?
      end
      Transaction.where(recorded_by: demo_users).delete_all

      demo_properties = Property.joins(:memberships).where(memberships: { user_id: demo_users }).distinct
      assessment_ids = DuesAssessment.where(property: demo_properties).pluck(:id)

      DuesPayment.where(dues_assessment_id: assessment_ids).delete_all
      DuesAssessment.where(id: assessment_ids).delete_all

      Membership.where(user: demo_users).delete_all

      orphan_properties = demo_properties.where.not(
        id: Membership.select(:property_id)
      )
      orphan_properties.destroy_all

      BudgetLine.where(
        account: Account.where("description LIKE ?", "%")
      ).where(fiscal_year: Date.current.year).delete_all

      demo_users.destroy_all
    end

    puts "  Done. Demo data removed."
  end
end
