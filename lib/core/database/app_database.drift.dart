// dart format width=80
// ignore_for_file: type=lint
part of 'app_database.dart';

class $BudgetConfigTable extends BudgetConfig
    with TableInfo<$BudgetConfigTable, BudgetConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetConfigTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _monthlyAllowanceMeta = const VerificationMeta(
    'monthlyAllowance',
  );
  @override
  late final GeneratedColumn<double> monthlyAllowance = GeneratedColumn<double>(
    'monthly_allowance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(15000.0),
  );
  static const VerificationMeta _currentBankBalanceMeta =
      const VerificationMeta('currentBankBalance');
  @override
  late final GeneratedColumn<double> currentBankBalance =
      GeneratedColumn<double>(
        'current_bank_balance',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(15000.0),
      );
  static const VerificationMeta _cycleResetDayMeta = const VerificationMeta(
    'cycleResetDay',
  );
  @override
  late final GeneratedColumn<int> cycleResetDay = GeneratedColumn<int>(
    'cycle_reset_day',
    aliasedName,
    false,
    check: () => ComparableExpr(cycleResetDay).isBetweenValues(1, 31),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currencySymbolMeta = const VerificationMeta(
    'currencySymbol',
  );
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
    'currency_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('₹'),
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerPaymentHandleMeta =
      const VerificationMeta('ownerPaymentHandle');
  @override
  late final GeneratedColumn<String> ownerPaymentHandle =
      GeneratedColumn<String>(
        'owner_payment_handle',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthlyAllowance,
    currentBankBalance,
    cycleResetDay,
    currencySymbol,
    ownerName,
    ownerPaymentHandle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_config';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monthly_allowance')) {
      context.handle(
        _monthlyAllowanceMeta,
        monthlyAllowance.isAcceptableOrUnknown(
          data['monthly_allowance']!,
          _monthlyAllowanceMeta,
        ),
      );
    }
    if (data.containsKey('current_bank_balance')) {
      context.handle(
        _currentBankBalanceMeta,
        currentBankBalance.isAcceptableOrUnknown(
          data['current_bank_balance']!,
          _currentBankBalanceMeta,
        ),
      );
    }
    if (data.containsKey('cycle_reset_day')) {
      context.handle(
        _cycleResetDayMeta,
        cycleResetDay.isAcceptableOrUnknown(
          data['cycle_reset_day']!,
          _cycleResetDayMeta,
        ),
      );
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
        _currencySymbolMeta,
        currencySymbol.isAcceptableOrUnknown(
          data['currency_symbol']!,
          _currencySymbolMeta,
        ),
      );
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('owner_payment_handle')) {
      context.handle(
        _ownerPaymentHandleMeta,
        ownerPaymentHandle.isAcceptableOrUnknown(
          data['owner_payment_handle']!,
          _ownerPaymentHandleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetConfigRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthlyAllowance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_allowance'],
      )!,
      currentBankBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_bank_balance'],
      )!,
      cycleResetDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_reset_day'],
      )!,
      currencySymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_symbol'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      ),
      ownerPaymentHandle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_payment_handle'],
      ),
    );
  }

  @override
  $BudgetConfigTable createAlias(String alias) {
    return $BudgetConfigTable(attachedDatabase, alias);
  }
}

class BudgetConfigRow extends DataClass implements Insertable<BudgetConfigRow> {
  final int id;
  final double monthlyAllowance;
  final double currentBankBalance;

  /// Day of month the allowance arrives. 29–31 clamp to the month's last day.
  final int cycleResetDay;
  final String currencySymbol;

  /// The user's own name and UPI ID / Venmo handle, put on shared ledger
  /// links so friends know who to pay (schema v2).
  final String? ownerName;
  final String? ownerPaymentHandle;
  const BudgetConfigRow({
    required this.id,
    required this.monthlyAllowance,
    required this.currentBankBalance,
    required this.cycleResetDay,
    required this.currencySymbol,
    this.ownerName,
    this.ownerPaymentHandle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monthly_allowance'] = Variable<double>(monthlyAllowance);
    map['current_bank_balance'] = Variable<double>(currentBankBalance);
    map['cycle_reset_day'] = Variable<int>(cycleResetDay);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    if (!nullToAbsent || ownerPaymentHandle != null) {
      map['owner_payment_handle'] = Variable<String>(ownerPaymentHandle);
    }
    return map;
  }

  BudgetConfigCompanion toCompanion(bool nullToAbsent) {
    return BudgetConfigCompanion(
      id: Value(id),
      monthlyAllowance: Value(monthlyAllowance),
      currentBankBalance: Value(currentBankBalance),
      cycleResetDay: Value(cycleResetDay),
      currencySymbol: Value(currencySymbol),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      ownerPaymentHandle: ownerPaymentHandle == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerPaymentHandle),
    );
  }

  factory BudgetConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetConfigRow(
      id: serializer.fromJson<int>(json['id']),
      monthlyAllowance: serializer.fromJson<double>(json['monthlyAllowance']),
      currentBankBalance: serializer.fromJson<double>(
        json['currentBankBalance'],
      ),
      cycleResetDay: serializer.fromJson<int>(json['cycleResetDay']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      ownerPaymentHandle: serializer.fromJson<String?>(
        json['ownerPaymentHandle'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthlyAllowance': serializer.toJson<double>(monthlyAllowance),
      'currentBankBalance': serializer.toJson<double>(currentBankBalance),
      'cycleResetDay': serializer.toJson<int>(cycleResetDay),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
      'ownerName': serializer.toJson<String?>(ownerName),
      'ownerPaymentHandle': serializer.toJson<String?>(ownerPaymentHandle),
    };
  }

  BudgetConfigRow copyWith({
    int? id,
    double? monthlyAllowance,
    double? currentBankBalance,
    int? cycleResetDay,
    String? currencySymbol,
    Value<String?> ownerName = const Value.absent(),
    Value<String?> ownerPaymentHandle = const Value.absent(),
  }) => BudgetConfigRow(
    id: id ?? this.id,
    monthlyAllowance: monthlyAllowance ?? this.monthlyAllowance,
    currentBankBalance: currentBankBalance ?? this.currentBankBalance,
    cycleResetDay: cycleResetDay ?? this.cycleResetDay,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    ownerName: ownerName.present ? ownerName.value : this.ownerName,
    ownerPaymentHandle: ownerPaymentHandle.present
        ? ownerPaymentHandle.value
        : this.ownerPaymentHandle,
  );
  BudgetConfigRow copyWithCompanion(BudgetConfigCompanion data) {
    return BudgetConfigRow(
      id: data.id.present ? data.id.value : this.id,
      monthlyAllowance: data.monthlyAllowance.present
          ? data.monthlyAllowance.value
          : this.monthlyAllowance,
      currentBankBalance: data.currentBankBalance.present
          ? data.currentBankBalance.value
          : this.currentBankBalance,
      cycleResetDay: data.cycleResetDay.present
          ? data.cycleResetDay.value
          : this.cycleResetDay,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      ownerPaymentHandle: data.ownerPaymentHandle.present
          ? data.ownerPaymentHandle.value
          : this.ownerPaymentHandle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetConfigRow(')
          ..write('id: $id, ')
          ..write('monthlyAllowance: $monthlyAllowance, ')
          ..write('currentBankBalance: $currentBankBalance, ')
          ..write('cycleResetDay: $cycleResetDay, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('ownerName: $ownerName, ')
          ..write('ownerPaymentHandle: $ownerPaymentHandle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthlyAllowance,
    currentBankBalance,
    cycleResetDay,
    currencySymbol,
    ownerName,
    ownerPaymentHandle,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetConfigRow &&
          other.id == this.id &&
          other.monthlyAllowance == this.monthlyAllowance &&
          other.currentBankBalance == this.currentBankBalance &&
          other.cycleResetDay == this.cycleResetDay &&
          other.currencySymbol == this.currencySymbol &&
          other.ownerName == this.ownerName &&
          other.ownerPaymentHandle == this.ownerPaymentHandle);
}

class BudgetConfigCompanion extends UpdateCompanion<BudgetConfigRow> {
  final Value<int> id;
  final Value<double> monthlyAllowance;
  final Value<double> currentBankBalance;
  final Value<int> cycleResetDay;
  final Value<String> currencySymbol;
  final Value<String?> ownerName;
  final Value<String?> ownerPaymentHandle;
  const BudgetConfigCompanion({
    this.id = const Value.absent(),
    this.monthlyAllowance = const Value.absent(),
    this.currentBankBalance = const Value.absent(),
    this.cycleResetDay = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.ownerPaymentHandle = const Value.absent(),
  });
  BudgetConfigCompanion.insert({
    this.id = const Value.absent(),
    this.monthlyAllowance = const Value.absent(),
    this.currentBankBalance = const Value.absent(),
    this.cycleResetDay = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.ownerPaymentHandle = const Value.absent(),
  });
  static Insertable<BudgetConfigRow> custom({
    Expression<int>? id,
    Expression<double>? monthlyAllowance,
    Expression<double>? currentBankBalance,
    Expression<int>? cycleResetDay,
    Expression<String>? currencySymbol,
    Expression<String>? ownerName,
    Expression<String>? ownerPaymentHandle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthlyAllowance != null) 'monthly_allowance': monthlyAllowance,
      if (currentBankBalance != null)
        'current_bank_balance': currentBankBalance,
      if (cycleResetDay != null) 'cycle_reset_day': cycleResetDay,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerPaymentHandle != null)
        'owner_payment_handle': ownerPaymentHandle,
    });
  }

  BudgetConfigCompanion copyWith({
    Value<int>? id,
    Value<double>? monthlyAllowance,
    Value<double>? currentBankBalance,
    Value<int>? cycleResetDay,
    Value<String>? currencySymbol,
    Value<String?>? ownerName,
    Value<String?>? ownerPaymentHandle,
  }) {
    return BudgetConfigCompanion(
      id: id ?? this.id,
      monthlyAllowance: monthlyAllowance ?? this.monthlyAllowance,
      currentBankBalance: currentBankBalance ?? this.currentBankBalance,
      cycleResetDay: cycleResetDay ?? this.cycleResetDay,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      ownerName: ownerName ?? this.ownerName,
      ownerPaymentHandle: ownerPaymentHandle ?? this.ownerPaymentHandle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthlyAllowance.present) {
      map['monthly_allowance'] = Variable<double>(monthlyAllowance.value);
    }
    if (currentBankBalance.present) {
      map['current_bank_balance'] = Variable<double>(currentBankBalance.value);
    }
    if (cycleResetDay.present) {
      map['cycle_reset_day'] = Variable<int>(cycleResetDay.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (ownerPaymentHandle.present) {
      map['owner_payment_handle'] = Variable<String>(ownerPaymentHandle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetConfigCompanion(')
          ..write('id: $id, ')
          ..write('monthlyAllowance: $monthlyAllowance, ')
          ..write('currentBankBalance: $currentBankBalance, ')
          ..write('cycleResetDay: $cycleResetDay, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('ownerName: $ownerName, ')
          ..write('ownerPaymentHandle: $ownerPaymentHandle')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, LedgerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPaidMeta = const VerificationMeta(
    'totalPaid',
  );
  @override
  late final GeneratedColumn<double> totalPaid = GeneratedColumn<double>(
    'total_paid',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _myShareMeta = const VerificationMeta(
    'myShare',
  );
  @override
  late final GeneratedColumn<double> myShare = GeneratedColumn<double>(
    'my_share',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnCategory>($TransactionsTable.$convertercategory);
  static const VerificationMeta _paidByMeMeta = const VerificationMeta(
    'paidByMe',
  );
  @override
  late final GeneratedColumn<bool> paidByMe = GeneratedColumn<bool>(
    'paid_by_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid_by_me" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxnSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxnSource>($TransactionsTable.$convertersource);
  static const VerificationMeta _receiptImagePathMeta = const VerificationMeta(
    'receiptImagePath',
  );
  @override
  late final GeneratedColumn<String> receiptImagePath = GeneratedColumn<String>(
    'receipt_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    merchant,
    totalPaid,
    myShare,
    category,
    paidByMe,
    source,
    receiptImagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('total_paid')) {
      context.handle(
        _totalPaidMeta,
        totalPaid.isAcceptableOrUnknown(data['total_paid']!, _totalPaidMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPaidMeta);
    }
    if (data.containsKey('my_share')) {
      context.handle(
        _myShareMeta,
        myShare.isAcceptableOrUnknown(data['my_share']!, _myShareMeta),
      );
    } else if (isInserting) {
      context.missing(_myShareMeta);
    }
    if (data.containsKey('paid_by_me')) {
      context.handle(
        _paidByMeMeta,
        paidByMe.isAcceptableOrUnknown(data['paid_by_me']!, _paidByMeMeta),
      );
    } else if (isInserting) {
      context.missing(_paidByMeMeta);
    }
    if (data.containsKey('receipt_image_path')) {
      context.handle(
        _receiptImagePathMeta,
        receiptImagePath.isAcceptableOrUnknown(
          data['receipt_image_path']!,
          _receiptImagePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      totalPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_paid'],
      )!,
      myShare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}my_share'],
      )!,
      category: $TransactionsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      paidByMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid_by_me'],
      )!,
      source: $TransactionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      receiptImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<TxnCategory, String> $convertercategory =
      const TxnCategoryConverter();
  static TypeConverter<TxnSource, String> $convertersource =
      const TxnSourceConverter();
}

class LedgerTransaction extends DataClass
    implements Insertable<LedgerTransaction> {
  final String id;
  final String merchant;

  /// Cash that left whoever paid (the user's bank when [paidByMe]).
  final double totalPaid;

  /// The user's personal cut: the only part that counts as spending.
  final double myShare;
  final TxnCategory category;
  final bool paidByMe;
  final TxnSource source;
  final String? receiptImagePath;
  final DateTime createdAt;
  const LedgerTransaction({
    required this.id,
    required this.merchant,
    required this.totalPaid,
    required this.myShare,
    required this.category,
    required this.paidByMe,
    required this.source,
    this.receiptImagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['merchant'] = Variable<String>(merchant);
    map['total_paid'] = Variable<double>(totalPaid);
    map['my_share'] = Variable<double>(myShare);
    {
      map['category'] = Variable<String>(
        $TransactionsTable.$convertercategory.toSql(category),
      );
    }
    map['paid_by_me'] = Variable<bool>(paidByMe);
    {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || receiptImagePath != null) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      merchant: Value(merchant),
      totalPaid: Value(totalPaid),
      myShare: Value(myShare),
      category: Value(category),
      paidByMe: Value(paidByMe),
      source: Value(source),
      receiptImagePath: receiptImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImagePath),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerTransaction(
      id: serializer.fromJson<String>(json['id']),
      merchant: serializer.fromJson<String>(json['merchant']),
      totalPaid: serializer.fromJson<double>(json['totalPaid']),
      myShare: serializer.fromJson<double>(json['myShare']),
      category: serializer.fromJson<TxnCategory>(json['category']),
      paidByMe: serializer.fromJson<bool>(json['paidByMe']),
      source: serializer.fromJson<TxnSource>(json['source']),
      receiptImagePath: serializer.fromJson<String?>(json['receiptImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'merchant': serializer.toJson<String>(merchant),
      'totalPaid': serializer.toJson<double>(totalPaid),
      'myShare': serializer.toJson<double>(myShare),
      'category': serializer.toJson<TxnCategory>(category),
      'paidByMe': serializer.toJson<bool>(paidByMe),
      'source': serializer.toJson<TxnSource>(source),
      'receiptImagePath': serializer.toJson<String?>(receiptImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerTransaction copyWith({
    String? id,
    String? merchant,
    double? totalPaid,
    double? myShare,
    TxnCategory? category,
    bool? paidByMe,
    TxnSource? source,
    Value<String?> receiptImagePath = const Value.absent(),
    DateTime? createdAt,
  }) => LedgerTransaction(
    id: id ?? this.id,
    merchant: merchant ?? this.merchant,
    totalPaid: totalPaid ?? this.totalPaid,
    myShare: myShare ?? this.myShare,
    category: category ?? this.category,
    paidByMe: paidByMe ?? this.paidByMe,
    source: source ?? this.source,
    receiptImagePath: receiptImagePath.present
        ? receiptImagePath.value
        : this.receiptImagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerTransaction copyWithCompanion(TransactionsCompanion data) {
    return LedgerTransaction(
      id: data.id.present ? data.id.value : this.id,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      totalPaid: data.totalPaid.present ? data.totalPaid.value : this.totalPaid,
      myShare: data.myShare.present ? data.myShare.value : this.myShare,
      category: data.category.present ? data.category.value : this.category,
      paidByMe: data.paidByMe.present ? data.paidByMe.value : this.paidByMe,
      source: data.source.present ? data.source.value : this.source,
      receiptImagePath: data.receiptImagePath.present
          ? data.receiptImagePath.value
          : this.receiptImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransaction(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('myShare: $myShare, ')
          ..write('category: $category, ')
          ..write('paidByMe: $paidByMe, ')
          ..write('source: $source, ')
          ..write('receiptImagePath: $receiptImagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    merchant,
    totalPaid,
    myShare,
    category,
    paidByMe,
    source,
    receiptImagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerTransaction &&
          other.id == this.id &&
          other.merchant == this.merchant &&
          other.totalPaid == this.totalPaid &&
          other.myShare == this.myShare &&
          other.category == this.category &&
          other.paidByMe == this.paidByMe &&
          other.source == this.source &&
          other.receiptImagePath == this.receiptImagePath &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<LedgerTransaction> {
  final Value<String> id;
  final Value<String> merchant;
  final Value<double> totalPaid;
  final Value<double> myShare;
  final Value<TxnCategory> category;
  final Value<bool> paidByMe;
  final Value<TxnSource> source;
  final Value<String?> receiptImagePath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.merchant = const Value.absent(),
    this.totalPaid = const Value.absent(),
    this.myShare = const Value.absent(),
    this.category = const Value.absent(),
    this.paidByMe = const Value.absent(),
    this.source = const Value.absent(),
    this.receiptImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String merchant,
    required double totalPaid,
    required double myShare,
    required TxnCategory category,
    required bool paidByMe,
    required TxnSource source,
    this.receiptImagePath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       merchant = Value(merchant),
       totalPaid = Value(totalPaid),
       myShare = Value(myShare),
       category = Value(category),
       paidByMe = Value(paidByMe),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<LedgerTransaction> custom({
    Expression<String>? id,
    Expression<String>? merchant,
    Expression<double>? totalPaid,
    Expression<double>? myShare,
    Expression<String>? category,
    Expression<bool>? paidByMe,
    Expression<String>? source,
    Expression<String>? receiptImagePath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchant != null) 'merchant': merchant,
      if (totalPaid != null) 'total_paid': totalPaid,
      if (myShare != null) 'my_share': myShare,
      if (category != null) 'category': category,
      if (paidByMe != null) 'paid_by_me': paidByMe,
      if (source != null) 'source': source,
      if (receiptImagePath != null) 'receipt_image_path': receiptImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? merchant,
    Value<double>? totalPaid,
    Value<double>? myShare,
    Value<TxnCategory>? category,
    Value<bool>? paidByMe,
    Value<TxnSource>? source,
    Value<String?>? receiptImagePath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      totalPaid: totalPaid ?? this.totalPaid,
      myShare: myShare ?? this.myShare,
      category: category ?? this.category,
      paidByMe: paidByMe ?? this.paidByMe,
      source: source ?? this.source,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (totalPaid.present) {
      map['total_paid'] = Variable<double>(totalPaid.value);
    }
    if (myShare.present) {
      map['my_share'] = Variable<double>(myShare.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $TransactionsTable.$convertercategory.toSql(category.value),
      );
    }
    if (paidByMe.present) {
      map['paid_by_me'] = Variable<bool>(paidByMe.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source.value),
      );
    }
    if (receiptImagePath.present) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('merchant: $merchant, ')
          ..write('totalPaid: $totalPaid, ')
          ..write('myShare: $myShare, ')
          ..write('category: $category, ')
          ..write('paidByMe: $paidByMe, ')
          ..write('source: $source, ')
          ..write('receiptImagePath: $receiptImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitEntriesTable extends SplitEntries
    with TableInfo<$SplitEntriesTable, SplitEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendNameMeta = const VerificationMeta(
    'friendName',
  );
  @override
  late final GeneratedColumn<String> friendName = GeneratedColumn<String>(
    'friend_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendPaymentHandleMeta =
      const VerificationMeta('friendPaymentHandle');
  @override
  late final GeneratedColumn<String> friendPaymentHandle =
      GeneratedColumn<String>(
        'friend_payment_handle',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SplitDirection, String>
  direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SplitDirection>($SplitEntriesTable.$converterdirection);
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    friendId,
    friendName,
    friendPaymentHandle,
    amount,
    direction,
    isSettled,
    settledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('friend_name')) {
      context.handle(
        _friendNameMeta,
        friendName.isAcceptableOrUnknown(data['friend_name']!, _friendNameMeta),
      );
    } else if (isInserting) {
      context.missing(_friendNameMeta);
    }
    if (data.containsKey('friend_payment_handle')) {
      context.handle(
        _friendPaymentHandleMeta,
        friendPaymentHandle.isAcceptableOrUnknown(
          data['friend_payment_handle']!,
          _friendPaymentHandleMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      friendName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_name'],
      )!,
      friendPaymentHandle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_payment_handle'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      direction: $SplitEntriesTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
    );
  }

  @override
  $SplitEntriesTable createAlias(String alias) {
    return $SplitEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<SplitDirection, String> $converterdirection =
      const SplitDirectionConverter();
}

class SplitEntry extends DataClass implements Insertable<SplitEntry> {
  final String id;
  final String transactionId;
  final String friendId;
  final String friendName;

  /// UPI ID (`name@okaxis`) or Venmo / Cash App handle.
  final String? friendPaymentHandle;
  final double amount;
  final SplitDirection direction;
  final bool isSettled;
  final DateTime? settledAt;
  const SplitEntry({
    required this.id,
    required this.transactionId,
    required this.friendId,
    required this.friendName,
    this.friendPaymentHandle,
    required this.amount,
    required this.direction,
    required this.isSettled,
    this.settledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['friend_id'] = Variable<String>(friendId);
    map['friend_name'] = Variable<String>(friendName);
    if (!nullToAbsent || friendPaymentHandle != null) {
      map['friend_payment_handle'] = Variable<String>(friendPaymentHandle);
    }
    map['amount'] = Variable<double>(amount);
    {
      map['direction'] = Variable<String>(
        $SplitEntriesTable.$converterdirection.toSql(direction),
      );
    }
    map['is_settled'] = Variable<bool>(isSettled);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    return map;
  }

  SplitEntriesCompanion toCompanion(bool nullToAbsent) {
    return SplitEntriesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      friendId: Value(friendId),
      friendName: Value(friendName),
      friendPaymentHandle: friendPaymentHandle == null && nullToAbsent
          ? const Value.absent()
          : Value(friendPaymentHandle),
      amount: Value(amount),
      direction: Value(direction),
      isSettled: Value(isSettled),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
    );
  }

  factory SplitEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitEntry(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      friendId: serializer.fromJson<String>(json['friendId']),
      friendName: serializer.fromJson<String>(json['friendName']),
      friendPaymentHandle: serializer.fromJson<String?>(
        json['friendPaymentHandle'],
      ),
      amount: serializer.fromJson<double>(json['amount']),
      direction: serializer.fromJson<SplitDirection>(json['direction']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'friendId': serializer.toJson<String>(friendId),
      'friendName': serializer.toJson<String>(friendName),
      'friendPaymentHandle': serializer.toJson<String?>(friendPaymentHandle),
      'amount': serializer.toJson<double>(amount),
      'direction': serializer.toJson<SplitDirection>(direction),
      'isSettled': serializer.toJson<bool>(isSettled),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
    };
  }

  SplitEntry copyWith({
    String? id,
    String? transactionId,
    String? friendId,
    String? friendName,
    Value<String?> friendPaymentHandle = const Value.absent(),
    double? amount,
    SplitDirection? direction,
    bool? isSettled,
    Value<DateTime?> settledAt = const Value.absent(),
  }) => SplitEntry(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    friendId: friendId ?? this.friendId,
    friendName: friendName ?? this.friendName,
    friendPaymentHandle: friendPaymentHandle.present
        ? friendPaymentHandle.value
        : this.friendPaymentHandle,
    amount: amount ?? this.amount,
    direction: direction ?? this.direction,
    isSettled: isSettled ?? this.isSettled,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
  );
  SplitEntry copyWithCompanion(SplitEntriesCompanion data) {
    return SplitEntry(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      friendName: data.friendName.present
          ? data.friendName.value
          : this.friendName,
      friendPaymentHandle: data.friendPaymentHandle.present
          ? data.friendPaymentHandle.value
          : this.friendPaymentHandle,
      amount: data.amount.present ? data.amount.value : this.amount,
      direction: data.direction.present ? data.direction.value : this.direction,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitEntry(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('friendPaymentHandle: $friendPaymentHandle, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('isSettled: $isSettled, ')
          ..write('settledAt: $settledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    friendId,
    friendName,
    friendPaymentHandle,
    amount,
    direction,
    isSettled,
    settledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitEntry &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.friendId == this.friendId &&
          other.friendName == this.friendName &&
          other.friendPaymentHandle == this.friendPaymentHandle &&
          other.amount == this.amount &&
          other.direction == this.direction &&
          other.isSettled == this.isSettled &&
          other.settledAt == this.settledAt);
}

class SplitEntriesCompanion extends UpdateCompanion<SplitEntry> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> friendId;
  final Value<String> friendName;
  final Value<String?> friendPaymentHandle;
  final Value<double> amount;
  final Value<SplitDirection> direction;
  final Value<bool> isSettled;
  final Value<DateTime?> settledAt;
  final Value<int> rowid;
  const SplitEntriesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.friendId = const Value.absent(),
    this.friendName = const Value.absent(),
    this.friendPaymentHandle = const Value.absent(),
    this.amount = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitEntriesCompanion.insert({
    required String id,
    required String transactionId,
    required String friendId,
    required String friendName,
    this.friendPaymentHandle = const Value.absent(),
    required double amount,
    required SplitDirection direction,
    this.isSettled = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       friendId = Value(friendId),
       friendName = Value(friendName),
       amount = Value(amount),
       direction = Value(direction);
  static Insertable<SplitEntry> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? friendId,
    Expression<String>? friendName,
    Expression<String>? friendPaymentHandle,
    Expression<double>? amount,
    Expression<String>? direction,
    Expression<bool>? isSettled,
    Expression<DateTime>? settledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (friendId != null) 'friend_id': friendId,
      if (friendName != null) 'friend_name': friendName,
      if (friendPaymentHandle != null)
        'friend_payment_handle': friendPaymentHandle,
      if (amount != null) 'amount': amount,
      if (direction != null) 'direction': direction,
      if (isSettled != null) 'is_settled': isSettled,
      if (settledAt != null) 'settled_at': settledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? friendId,
    Value<String>? friendName,
    Value<String?>? friendPaymentHandle,
    Value<double>? amount,
    Value<SplitDirection>? direction,
    Value<bool>? isSettled,
    Value<DateTime?>? settledAt,
    Value<int>? rowid,
  }) {
    return SplitEntriesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendPaymentHandle: friendPaymentHandle ?? this.friendPaymentHandle,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (friendName.present) {
      map['friend_name'] = Variable<String>(friendName.value);
    }
    if (friendPaymentHandle.present) {
      map['friend_payment_handle'] = Variable<String>(
        friendPaymentHandle.value,
      );
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $SplitEntriesTable.$converterdirection.toSql(direction.value),
      );
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitEntriesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('friendPaymentHandle: $friendPaymentHandle, ')
          ..write('amount: $amount, ')
          ..write('direction: $direction, ')
          ..write('isSettled: $isSettled, ')
          ..write('settledAt: $settledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FinancialSummaryViewData extends DataClass {
  final double? monthlyAllowance;
  final double? bankBalance;
  final double totalPersonalSpend;
  final double totalOwedToMe;
  final double totalIOwe;
  const FinancialSummaryViewData({
    this.monthlyAllowance,
    this.bankBalance,
    required this.totalPersonalSpend,
    required this.totalOwedToMe,
    required this.totalIOwe,
  });
  factory FinancialSummaryViewData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialSummaryViewData(
      monthlyAllowance: serializer.fromJson<double?>(json['monthly_allowance']),
      bankBalance: serializer.fromJson<double?>(json['bank_balance']),
      totalPersonalSpend: serializer.fromJson<double>(
        json['total_personal_spend'],
      ),
      totalOwedToMe: serializer.fromJson<double>(json['total_owed_to_me']),
      totalIOwe: serializer.fromJson<double>(json['total_i_owe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthly_allowance': serializer.toJson<double?>(monthlyAllowance),
      'bank_balance': serializer.toJson<double?>(bankBalance),
      'total_personal_spend': serializer.toJson<double>(totalPersonalSpend),
      'total_owed_to_me': serializer.toJson<double>(totalOwedToMe),
      'total_i_owe': serializer.toJson<double>(totalIOwe),
    };
  }

  FinancialSummaryViewData copyWith({
    Value<double?> monthlyAllowance = const Value.absent(),
    Value<double?> bankBalance = const Value.absent(),
    double? totalPersonalSpend,
    double? totalOwedToMe,
    double? totalIOwe,
  }) => FinancialSummaryViewData(
    monthlyAllowance: monthlyAllowance.present
        ? monthlyAllowance.value
        : this.monthlyAllowance,
    bankBalance: bankBalance.present ? bankBalance.value : this.bankBalance,
    totalPersonalSpend: totalPersonalSpend ?? this.totalPersonalSpend,
    totalOwedToMe: totalOwedToMe ?? this.totalOwedToMe,
    totalIOwe: totalIOwe ?? this.totalIOwe,
  );
  @override
  String toString() {
    return (StringBuffer('FinancialSummaryViewData(')
          ..write('monthlyAllowance: $monthlyAllowance, ')
          ..write('bankBalance: $bankBalance, ')
          ..write('totalPersonalSpend: $totalPersonalSpend, ')
          ..write('totalOwedToMe: $totalOwedToMe, ')
          ..write('totalIOwe: $totalIOwe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    monthlyAllowance,
    bankBalance,
    totalPersonalSpend,
    totalOwedToMe,
    totalIOwe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialSummaryViewData &&
          other.monthlyAllowance == this.monthlyAllowance &&
          other.bankBalance == this.bankBalance &&
          other.totalPersonalSpend == this.totalPersonalSpend &&
          other.totalOwedToMe == this.totalOwedToMe &&
          other.totalIOwe == this.totalIOwe);
}

class FinancialSummaryView
    extends ViewInfo<FinancialSummaryView, FinancialSummaryViewData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  FinancialSummaryView(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    monthlyAllowance,
    bankBalance,
    totalPersonalSpend,
    totalOwedToMe,
    totalIOwe,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'financial_summary_view';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW IF NOT EXISTS financial_summary_view AS SELECT (SELECT monthly_allowance FROM budget_config WHERE id = 1) AS monthly_allowance, (SELECT current_bank_balance FROM budget_config WHERE id = 1) AS bank_balance, COALESCE((SELECT SUM(my_share) FROM transactions), 0.0) AS total_personal_spend, COALESCE((SELECT SUM(amount) FROM split_entries WHERE direction = \'OWES_ME\' AND is_settled = 0), 0.0) AS total_owed_to_me, COALESCE((SELECT SUM(amount) FROM split_entries WHERE direction = \'I_OWE\' AND is_settled = 0), 0.0) AS total_i_owe',
  };
  @override
  FinancialSummaryView get asDslTable => this;
  @override
  FinancialSummaryViewData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialSummaryViewData(
      monthlyAllowance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_allowance'],
      ),
      bankBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bank_balance'],
      ),
      totalPersonalSpend: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_personal_spend'],
      )!,
      totalOwedToMe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_owed_to_me'],
      )!,
      totalIOwe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_i_owe'],
      )!,
    );
  }

  late final GeneratedColumn<double> monthlyAllowance = GeneratedColumn<double>(
    'monthly_allowance',
    aliasedName,
    true,
    type: DriftSqlType.double,
  );
  late final GeneratedColumn<double> bankBalance = GeneratedColumn<double>(
    'bank_balance',
    aliasedName,
    true,
    type: DriftSqlType.double,
  );
  late final GeneratedColumn<double> totalPersonalSpend =
      GeneratedColumn<double>(
        'total_personal_spend',
        aliasedName,
        false,
        type: DriftSqlType.double,
      );
  late final GeneratedColumn<double> totalOwedToMe = GeneratedColumn<double>(
    'total_owed_to_me',
    aliasedName,
    false,
    type: DriftSqlType.double,
  );
  late final GeneratedColumn<double> totalIOwe = GeneratedColumn<double>(
    'total_i_owe',
    aliasedName,
    false,
    type: DriftSqlType.double,
  );
  @override
  FinancialSummaryView createAlias(String alias) {
    return FinancialSummaryView(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'budget_config',
    'transactions',
    'split_entries',
  };
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _myShareMeta = const VerificationMeta(
    'myShare',
  );
  @override
  late final GeneratedColumn<double> myShare = GeneratedColumn<double>(
    'my_share',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billingDateMeta = const VerificationMeta(
    'billingDate',
  );
  @override
  late final GeneratedColumn<DateTime> billingDate = GeneratedColumn<DateTime>(
    'billing_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFreeTrialMeta = const VerificationMeta(
    'isFreeTrial',
  );
  @override
  late final GeneratedColumn<bool> isFreeTrial = GeneratedColumn<bool>(
    'is_free_trial',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_free_trial" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<SplitGroupMember>?, String>
  autoSplitGroupJson =
      GeneratedColumn<String>(
        'auto_split_group_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<SplitGroupMember>?>(
        $SubscriptionsTable.$converterautoSplitGroupJsonn,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cancelUrlMeta = const VerificationMeta(
    'cancelUrl',
  );
  @override
  late final GeneratedColumn<String> cancelUrl = GeneratedColumn<String>(
    'cancel_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    myShare,
    billingDate,
    isFreeTrial,
    autoSplitGroupJson,
    isActive,
    cancelUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('my_share')) {
      context.handle(
        _myShareMeta,
        myShare.isAcceptableOrUnknown(data['my_share']!, _myShareMeta),
      );
    } else if (isInserting) {
      context.missing(_myShareMeta);
    }
    if (data.containsKey('billing_date')) {
      context.handle(
        _billingDateMeta,
        billingDate.isAcceptableOrUnknown(
          data['billing_date']!,
          _billingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billingDateMeta);
    }
    if (data.containsKey('is_free_trial')) {
      context.handle(
        _isFreeTrialMeta,
        isFreeTrial.isAcceptableOrUnknown(
          data['is_free_trial']!,
          _isFreeTrialMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cancel_url')) {
      context.handle(
        _cancelUrlMeta,
        cancelUrl.isAcceptableOrUnknown(data['cancel_url']!, _cancelUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      myShare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}my_share'],
      )!,
      billingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}billing_date'],
      )!,
      isFreeTrial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_free_trial'],
      )!,
      autoSplitGroupJson: $SubscriptionsTable.$converterautoSplitGroupJsonn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}auto_split_group_json'],
            ),
          ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cancelUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_url'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<SplitGroupMember>, String>
  $converterautoSplitGroupJson = const SplitGroupConverter();
  static TypeConverter<List<SplitGroupMember>?, String?>
  $converterautoSplitGroupJsonn = NullAwareTypeConverter.wrap(
    $converterautoSplitGroupJson,
  );
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String id;
  final String name;
  final double amount;
  final double myShare;

  /// Next charge time.
  final DateTime billingDate;
  final bool isFreeTrial;
  final List<SplitGroupMember>? autoSplitGroupJson;
  final bool isActive;

  /// Where to cancel a free trial before it converts (Free Trial Shield).
  final String? cancelUrl;
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.myShare,
    required this.billingDate,
    required this.isFreeTrial,
    this.autoSplitGroupJson,
    required this.isActive,
    this.cancelUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['my_share'] = Variable<double>(myShare);
    map['billing_date'] = Variable<DateTime>(billingDate);
    map['is_free_trial'] = Variable<bool>(isFreeTrial);
    if (!nullToAbsent || autoSplitGroupJson != null) {
      map['auto_split_group_json'] = Variable<String>(
        $SubscriptionsTable.$converterautoSplitGroupJsonn.toSql(
          autoSplitGroupJson,
        ),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || cancelUrl != null) {
      map['cancel_url'] = Variable<String>(cancelUrl);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      myShare: Value(myShare),
      billingDate: Value(billingDate),
      isFreeTrial: Value(isFreeTrial),
      autoSplitGroupJson: autoSplitGroupJson == null && nullToAbsent
          ? const Value.absent()
          : Value(autoSplitGroupJson),
      isActive: Value(isActive),
      cancelUrl: cancelUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelUrl),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      myShare: serializer.fromJson<double>(json['myShare']),
      billingDate: serializer.fromJson<DateTime>(json['billingDate']),
      isFreeTrial: serializer.fromJson<bool>(json['isFreeTrial']),
      autoSplitGroupJson: serializer.fromJson<List<SplitGroupMember>?>(
        json['autoSplitGroupJson'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cancelUrl: serializer.fromJson<String?>(json['cancelUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'myShare': serializer.toJson<double>(myShare),
      'billingDate': serializer.toJson<DateTime>(billingDate),
      'isFreeTrial': serializer.toJson<bool>(isFreeTrial),
      'autoSplitGroupJson': serializer.toJson<List<SplitGroupMember>?>(
        autoSplitGroupJson,
      ),
      'isActive': serializer.toJson<bool>(isActive),
      'cancelUrl': serializer.toJson<String?>(cancelUrl),
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? amount,
    double? myShare,
    DateTime? billingDate,
    bool? isFreeTrial,
    Value<List<SplitGroupMember>?> autoSplitGroupJson = const Value.absent(),
    bool? isActive,
    Value<String?> cancelUrl = const Value.absent(),
  }) => Subscription(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    myShare: myShare ?? this.myShare,
    billingDate: billingDate ?? this.billingDate,
    isFreeTrial: isFreeTrial ?? this.isFreeTrial,
    autoSplitGroupJson: autoSplitGroupJson.present
        ? autoSplitGroupJson.value
        : this.autoSplitGroupJson,
    isActive: isActive ?? this.isActive,
    cancelUrl: cancelUrl.present ? cancelUrl.value : this.cancelUrl,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      myShare: data.myShare.present ? data.myShare.value : this.myShare,
      billingDate: data.billingDate.present
          ? data.billingDate.value
          : this.billingDate,
      isFreeTrial: data.isFreeTrial.present
          ? data.isFreeTrial.value
          : this.isFreeTrial,
      autoSplitGroupJson: data.autoSplitGroupJson.present
          ? data.autoSplitGroupJson.value
          : this.autoSplitGroupJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cancelUrl: data.cancelUrl.present ? data.cancelUrl.value : this.cancelUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('myShare: $myShare, ')
          ..write('billingDate: $billingDate, ')
          ..write('isFreeTrial: $isFreeTrial, ')
          ..write('autoSplitGroupJson: $autoSplitGroupJson, ')
          ..write('isActive: $isActive, ')
          ..write('cancelUrl: $cancelUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    myShare,
    billingDate,
    isFreeTrial,
    autoSplitGroupJson,
    isActive,
    cancelUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.myShare == this.myShare &&
          other.billingDate == this.billingDate &&
          other.isFreeTrial == this.isFreeTrial &&
          other.autoSplitGroupJson == this.autoSplitGroupJson &&
          other.isActive == this.isActive &&
          other.cancelUrl == this.cancelUrl);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<double> myShare;
  final Value<DateTime> billingDate;
  final Value<bool> isFreeTrial;
  final Value<List<SplitGroupMember>?> autoSplitGroupJson;
  final Value<bool> isActive;
  final Value<String?> cancelUrl;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.myShare = const Value.absent(),
    this.billingDate = const Value.absent(),
    this.isFreeTrial = const Value.absent(),
    this.autoSplitGroupJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cancelUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String id,
    required String name,
    required double amount,
    required double myShare,
    required DateTime billingDate,
    this.isFreeTrial = const Value.absent(),
    this.autoSplitGroupJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cancelUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amount = Value(amount),
       myShare = Value(myShare),
       billingDate = Value(billingDate);
  static Insertable<Subscription> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<double>? myShare,
    Expression<DateTime>? billingDate,
    Expression<bool>? isFreeTrial,
    Expression<String>? autoSplitGroupJson,
    Expression<bool>? isActive,
    Expression<String>? cancelUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (myShare != null) 'my_share': myShare,
      if (billingDate != null) 'billing_date': billingDate,
      if (isFreeTrial != null) 'is_free_trial': isFreeTrial,
      if (autoSplitGroupJson != null)
        'auto_split_group_json': autoSplitGroupJson,
      if (isActive != null) 'is_active': isActive,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<double>? myShare,
    Value<DateTime>? billingDate,
    Value<bool>? isFreeTrial,
    Value<List<SplitGroupMember>?>? autoSplitGroupJson,
    Value<bool>? isActive,
    Value<String?>? cancelUrl,
    Value<int>? rowid,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      myShare: myShare ?? this.myShare,
      billingDate: billingDate ?? this.billingDate,
      isFreeTrial: isFreeTrial ?? this.isFreeTrial,
      autoSplitGroupJson: autoSplitGroupJson ?? this.autoSplitGroupJson,
      isActive: isActive ?? this.isActive,
      cancelUrl: cancelUrl ?? this.cancelUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (myShare.present) {
      map['my_share'] = Variable<double>(myShare.value);
    }
    if (billingDate.present) {
      map['billing_date'] = Variable<DateTime>(billingDate.value);
    }
    if (isFreeTrial.present) {
      map['is_free_trial'] = Variable<bool>(isFreeTrial.value);
    }
    if (autoSplitGroupJson.present) {
      map['auto_split_group_json'] = Variable<String>(
        $SubscriptionsTable.$converterautoSplitGroupJsonn.toSql(
          autoSplitGroupJson.value,
        ),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cancelUrl.present) {
      map['cancel_url'] = Variable<String>(cancelUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('myShare: $myShare, ')
          ..write('billingDate: $billingDate, ')
          ..write('isFreeTrial: $isFreeTrial, ')
          ..write('autoSplitGroupJson: $autoSplitGroupJson, ')
          ..write('isActive: $isActive, ')
          ..write('cancelUrl: $cancelUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BudgetConfigTable budgetConfig = $BudgetConfigTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SplitEntriesTable splitEntries = $SplitEntriesTable(this);
  late final FinancialSummaryView financialSummaryView = FinancialSummaryView(
    this,
  );
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final Index idxTransactionsCreatedAt = Index(
    'idx_transactions_created_at',
    'CREATE INDEX idx_transactions_created_at ON transactions (created_at)',
  );
  late final Index idxSplitEntriesTransaction = Index(
    'idx_split_entries_transaction',
    'CREATE INDEX idx_split_entries_transaction ON split_entries (transaction_id)',
  );
  late final Index idxSplitEntriesFriendOpen = Index(
    'idx_split_entries_friend_open',
    'CREATE INDEX idx_split_entries_friend_open ON split_entries (friend_id, is_settled)',
  );
  late final Index idxSubscriptionsBilling = Index(
    'idx_subscriptions_billing',
    'CREATE INDEX idx_subscriptions_billing ON subscriptions (is_active, billing_date)',
  );
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  late final BudgetDao budgetDao = BudgetDao(this as AppDatabase);
  late final SubscriptionsDao subscriptionsDao = SubscriptionsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    budgetConfig,
    transactions,
    splitEntries,
    financialSummaryView,
    subscriptions,
    idxTransactionsCreatedAt,
    idxSplitEntriesTransaction,
    idxSplitEntriesFriendOpen,
    idxSubscriptionsBilling,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('split_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BudgetConfigTableCreateCompanionBuilder =
    BudgetConfigCompanion Function({
      Value<int> id,
      Value<double> monthlyAllowance,
      Value<double> currentBankBalance,
      Value<int> cycleResetDay,
      Value<String> currencySymbol,
      Value<String?> ownerName,
      Value<String?> ownerPaymentHandle,
    });
typedef $$BudgetConfigTableUpdateCompanionBuilder =
    BudgetConfigCompanion Function({
      Value<int> id,
      Value<double> monthlyAllowance,
      Value<double> currentBankBalance,
      Value<int> cycleResetDay,
      Value<String> currencySymbol,
      Value<String?> ownerName,
      Value<String?> ownerPaymentHandle,
    });

class $$BudgetConfigTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetConfigTable> {
  $$BudgetConfigTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyAllowance => $composableBuilder(
    column: $table.monthlyAllowance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBankBalance => $composableBuilder(
    column: $table.currentBankBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleResetDay => $composableBuilder(
    column: $table.cycleResetDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerPaymentHandle => $composableBuilder(
    column: $table.ownerPaymentHandle,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetConfigTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetConfigTable> {
  $$BudgetConfigTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyAllowance => $composableBuilder(
    column: $table.monthlyAllowance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBankBalance => $composableBuilder(
    column: $table.currentBankBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleResetDay => $composableBuilder(
    column: $table.cycleResetDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerPaymentHandle => $composableBuilder(
    column: $table.ownerPaymentHandle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetConfigTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetConfigTable> {
  $$BudgetConfigTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monthlyAllowance => $composableBuilder(
    column: $table.monthlyAllowance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBankBalance => $composableBuilder(
    column: $table.currentBankBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleResetDay => $composableBuilder(
    column: $table.cycleResetDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
    column: $table.currencySymbol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get ownerPaymentHandle => $composableBuilder(
    column: $table.ownerPaymentHandle,
    builder: (column) => column,
  );
}

class $$BudgetConfigTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetConfigTable,
          BudgetConfigRow,
          $$BudgetConfigTableFilterComposer,
          $$BudgetConfigTableOrderingComposer,
          $$BudgetConfigTableAnnotationComposer,
          $$BudgetConfigTableCreateCompanionBuilder,
          $$BudgetConfigTableUpdateCompanionBuilder,
          (
            BudgetConfigRow,
            BaseReferences<_$AppDatabase, $BudgetConfigTable, BudgetConfigRow>,
          ),
          BudgetConfigRow,
          PrefetchHooks Function()
        > {
  $$BudgetConfigTableTableManager(_$AppDatabase db, $BudgetConfigTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetConfigTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetConfigTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetConfigTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monthlyAllowance = const Value.absent(),
                Value<double> currentBankBalance = const Value.absent(),
                Value<int> cycleResetDay = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String?> ownerName = const Value.absent(),
                Value<String?> ownerPaymentHandle = const Value.absent(),
              }) => BudgetConfigCompanion(
                id: id,
                monthlyAllowance: monthlyAllowance,
                currentBankBalance: currentBankBalance,
                cycleResetDay: cycleResetDay,
                currencySymbol: currencySymbol,
                ownerName: ownerName,
                ownerPaymentHandle: ownerPaymentHandle,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monthlyAllowance = const Value.absent(),
                Value<double> currentBankBalance = const Value.absent(),
                Value<int> cycleResetDay = const Value.absent(),
                Value<String> currencySymbol = const Value.absent(),
                Value<String?> ownerName = const Value.absent(),
                Value<String?> ownerPaymentHandle = const Value.absent(),
              }) => BudgetConfigCompanion.insert(
                id: id,
                monthlyAllowance: monthlyAllowance,
                currentBankBalance: currentBankBalance,
                cycleResetDay: cycleResetDay,
                currencySymbol: currencySymbol,
                ownerName: ownerName,
                ownerPaymentHandle: ownerPaymentHandle,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetConfigTable, BudgetConfigRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BudgetConfigTable,
                    BudgetConfigRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetConfigTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetConfigTable,
      BudgetConfigRow,
      $$BudgetConfigTableFilterComposer,
      $$BudgetConfigTableOrderingComposer,
      $$BudgetConfigTableAnnotationComposer,
      $$BudgetConfigTableCreateCompanionBuilder,
      $$BudgetConfigTableUpdateCompanionBuilder,
      (
        BudgetConfigRow,
        BaseReferences<_$AppDatabase, $BudgetConfigTable, BudgetConfigRow>,
      ),
      BudgetConfigRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String merchant,
      required double totalPaid,
      required double myShare,
      required TxnCategory category,
      required bool paidByMe,
      required TxnSource source,
      Value<String?> receiptImagePath,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> merchant,
      Value<double> totalPaid,
      Value<double> myShare,
      Value<TxnCategory> category,
      Value<bool> paidByMe,
      Value<TxnSource> source,
      Value<String?> receiptImagePath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TransactionsTable, LedgerTransaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SplitEntriesTable, List<SplitEntry>>
  _splitEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.splitEntries,
    aliasName: 'transactions__id__split_entries__transaction_id',
  );

  $$SplitEntriesTableProcessedTableManager get splitEntriesRefs {
    final manager = $$SplitEntriesTableTableManager(
      $_db,
      $_db.splitEntries,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPaid => $composableBuilder(
    column: $table.totalPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get myShare => $composableBuilder(
    column: $table.myShare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxnCategory, TxnCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get paidByMe => $composableBuilder(
    column: $table.paidByMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxnSource, TxnSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> splitEntriesRefs(
    Expression<bool> Function($$SplitEntriesTableFilterComposer f) f,
  ) {
    final $$SplitEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitEntries,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitEntriesTableFilterComposer(
            $db: $db,
            $table: $db.splitEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPaid => $composableBuilder(
    column: $table.totalPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get myShare => $composableBuilder(
    column: $table.myShare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paidByMe => $composableBuilder(
    column: $table.paidByMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<double> get totalPaid =>
      $composableBuilder(column: $table.totalPaid, builder: (column) => column);

  GeneratedColumn<double> get myShare =>
      $composableBuilder(column: $table.myShare, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get paidByMe =>
      $composableBuilder(column: $table.paidByMe, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxnSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> splitEntriesRefs<T extends Object>(
    Expression<T> Function($$SplitEntriesTableAnnotationComposer a) f,
  ) {
    final $$SplitEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitEntries,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.splitEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          LedgerTransaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (LedgerTransaction, $$TransactionsTableReferences),
          LedgerTransaction,
          PrefetchHooks Function({bool splitEntriesRefs})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<double> totalPaid = const Value.absent(),
                Value<double> myShare = const Value.absent(),
                Value<TxnCategory> category = const Value.absent(),
                Value<bool> paidByMe = const Value.absent(),
                Value<TxnSource> source = const Value.absent(),
                Value<String?> receiptImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                merchant: merchant,
                totalPaid: totalPaid,
                myShare: myShare,
                category: category,
                paidByMe: paidByMe,
                source: source,
                receiptImagePath: receiptImagePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String merchant,
                required double totalPaid,
                required double myShare,
                required TxnCategory category,
                required bool paidByMe,
                required TxnSource source,
                Value<String?> receiptImagePath = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                merchant: merchant,
                totalPaid: totalPaid,
                myShare: myShare,
                category: category,
                paidByMe: paidByMe,
                source: source,
                receiptImagePath: receiptImagePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, LedgerTransaction>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({splitEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (splitEntriesRefs) db.splitEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (splitEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      LedgerTransaction,
                      $TransactionsTable,
                      SplitEntry,
                      $SplitEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$TransactionsTableReferences
                          ._splitEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransactionsTableReferences(
                            db,
                            table,
                            p0,
                          ).splitEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'transaction_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      LedgerTransaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (LedgerTransaction, $$TransactionsTableReferences),
      LedgerTransaction,
      PrefetchHooks Function({bool splitEntriesRefs})
    >;
typedef $$SplitEntriesTableCreateCompanionBuilder =
    SplitEntriesCompanion Function({
      required String id,
      required String transactionId,
      required String friendId,
      required String friendName,
      Value<String?> friendPaymentHandle,
      required double amount,
      required SplitDirection direction,
      Value<bool> isSettled,
      Value<DateTime?> settledAt,
      Value<int> rowid,
    });
typedef $$SplitEntriesTableUpdateCompanionBuilder =
    SplitEntriesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> friendId,
      Value<String> friendName,
      Value<String?> friendPaymentHandle,
      Value<double> amount,
      Value<SplitDirection> direction,
      Value<bool> isSettled,
      Value<DateTime?> settledAt,
      Value<int> rowid,
    });

final class $$SplitEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $SplitEntriesTable, SplitEntry> {
  $$SplitEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('split_entries__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SplitEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendPaymentHandle => $composableBuilder(
    column: $table.friendPaymentHandle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SplitDirection, SplitDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendPaymentHandle => $composableBuilder(
    column: $table.friendPaymentHandle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get friendPaymentHandle => $composableBuilder(
    column: $table.friendPaymentHandle,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SplitDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitEntriesTable,
          SplitEntry,
          $$SplitEntriesTableFilterComposer,
          $$SplitEntriesTableOrderingComposer,
          $$SplitEntriesTableAnnotationComposer,
          $$SplitEntriesTableCreateCompanionBuilder,
          $$SplitEntriesTableUpdateCompanionBuilder,
          (SplitEntry, $$SplitEntriesTableReferences),
          SplitEntry,
          PrefetchHooks Function({bool transactionId})
        > {
  $$SplitEntriesTableTableManager(_$AppDatabase db, $SplitEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> friendId = const Value.absent(),
                Value<String> friendName = const Value.absent(),
                Value<String?> friendPaymentHandle = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<SplitDirection> direction = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitEntriesCompanion(
                id: id,
                transactionId: transactionId,
                friendId: friendId,
                friendName: friendName,
                friendPaymentHandle: friendPaymentHandle,
                amount: amount,
                direction: direction,
                isSettled: isSettled,
                settledAt: settledAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String friendId,
                required String friendName,
                Value<String?> friendPaymentHandle = const Value.absent(),
                required double amount,
                required SplitDirection direction,
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitEntriesCompanion.insert(
                id: id,
                transactionId: transactionId,
                friendId: friendId,
                friendName: friendName,
                friendPaymentHandle: friendPaymentHandle,
                amount: amount,
                direction: direction,
                isSettled: isSettled,
                settledAt: settledAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SplitEntriesTable, SplitEntry>(table),
                  $$SplitEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$SplitEntriesTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$SplitEntriesTableReferences
                            ._transactionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SplitEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitEntriesTable,
      SplitEntry,
      $$SplitEntriesTableFilterComposer,
      $$SplitEntriesTableOrderingComposer,
      $$SplitEntriesTableAnnotationComposer,
      $$SplitEntriesTableCreateCompanionBuilder,
      $$SplitEntriesTableUpdateCompanionBuilder,
      (SplitEntry, $$SplitEntriesTableReferences),
      SplitEntry,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      required String id,
      required String name,
      required double amount,
      required double myShare,
      required DateTime billingDate,
      Value<bool> isFreeTrial,
      Value<List<SplitGroupMember>?> autoSplitGroupJson,
      Value<bool> isActive,
      Value<String?> cancelUrl,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> amount,
      Value<double> myShare,
      Value<DateTime> billingDate,
      Value<bool> isFreeTrial,
      Value<List<SplitGroupMember>?> autoSplitGroupJson,
      Value<bool> isActive,
      Value<String?> cancelUrl,
      Value<int> rowid,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get myShare => $composableBuilder(
    column: $table.myShare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFreeTrial => $composableBuilder(
    column: $table.isFreeTrial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<SplitGroupMember>?,
    List<SplitGroupMember>,
    String
  >
  get autoSplitGroupJson => $composableBuilder(
    column: $table.autoSplitGroupJson,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelUrl => $composableBuilder(
    column: $table.cancelUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get myShare => $composableBuilder(
    column: $table.myShare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFreeTrial => $composableBuilder(
    column: $table.isFreeTrial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get autoSplitGroupJson => $composableBuilder(
    column: $table.autoSplitGroupJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelUrl => $composableBuilder(
    column: $table.cancelUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get myShare =>
      $composableBuilder(column: $table.myShare, builder: (column) => column);

  GeneratedColumn<DateTime> get billingDate => $composableBuilder(
    column: $table.billingDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFreeTrial => $composableBuilder(
    column: $table.isFreeTrial,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<SplitGroupMember>?, String>
  get autoSplitGroupJson => $composableBuilder(
    column: $table.autoSplitGroupJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get cancelUrl =>
      $composableBuilder(column: $table.cancelUrl, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            Subscription,
            BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
          ),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> myShare = const Value.absent(),
                Value<DateTime> billingDate = const Value.absent(),
                Value<bool> isFreeTrial = const Value.absent(),
                Value<List<SplitGroupMember>?> autoSplitGroupJson =
                    const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> cancelUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                amount: amount,
                myShare: myShare,
                billingDate: billingDate,
                isFreeTrial: isFreeTrial,
                autoSplitGroupJson: autoSplitGroupJson,
                isActive: isActive,
                cancelUrl: cancelUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double amount,
                required double myShare,
                required DateTime billingDate,
                Value<bool> isFreeTrial = const Value.absent(),
                Value<List<SplitGroupMember>?> autoSplitGroupJson =
                    const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> cancelUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                myShare: myShare,
                billingDate: billingDate,
                isFreeTrial: isFreeTrial,
                autoSplitGroupJson: autoSplitGroupJson,
                isActive: isActive,
                cancelUrl: cancelUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionsTable, Subscription>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SubscriptionsTable,
                    Subscription
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        Subscription,
        BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
      ),
      Subscription,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BudgetConfigTableTableManager get budgetConfig =>
      $$BudgetConfigTableTableManager(_db, _db.budgetConfig);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SplitEntriesTableTableManager get splitEntries =>
      $$SplitEntriesTableTableManager(_db, _db.splitEntries);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
}
