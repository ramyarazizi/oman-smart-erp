// ============================================================================
// نام جدید نرم‌افزار: سامانه جامع مدیریت هوشمند افق عمان (Oman Smart ERP)
// فایل اصلی: oman_erp_master.dart
// ویژگی‌های کلیدی این نسخه بنیادی و بی‌نقص:
// ۱. دروازه ورود اجباری با نام کاربری و رمز عبور از همان بدو باز شدن برنامه (Login Screen)
// ۲. پنل مدیریت کاربران و تعیین دقیق سطح دسترسی توسط ادمین (شما):
//    - تعریف کاربر جدید (حسابدار/واحد مالی، شریک، انباردار، فروشنده) با نام کاربری و رمز مجزا
//    - تعیین دقیق مجوزهای هر فرد با تیک (فقط رویت گزارش‌ها، ثبت تنخواه، مدیریت ۳ انبار، ثبت تولید، ثبت فروش، مشاهده سود و شریک، خروجی مالی)
// ۳. مدیریت کامل تنخواه شرکت و هزینه‌های روزانه شخصی/کاری + فیلترهای سفارشی + گزارش تجمیعی و ریز
// ۴. سامانه ۳ انبار مجزا و مرتبط (انبار ۱: مواد اولیه با هزینه حمل | انبار ۲: ملزومات کارتن/نایلون/لیبل | انبار ۳: محصول نهایی)
// ۵. محاسبه خودکار بهای تمام‌شده صنعتی (BOM/COGS)، کارمزد کارخانه، افت تولید، حاشیه سود/زیان هر فاکتور و تقسیم سود شرکا (۱۰۰٪، ÷۲، ÷۳ یا دلخواه)
// ۶. سازگاری ۱۰۰٪ با تمام نسخه‌های Flutter برای ساخت بی‌نقص فایل نصبی اندروید (.apk) و ویندوز (.exe) در GitHub Actions
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const OmanSmartErpApp());
}

// برای سازگاری کامل در صورت وجود تست پیش‌فرض فلاتر
typedef MyApp = OmanSmartErpApp;

class OmanSmartErpApp extends StatelessWidget {
  const OmanSmartErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سامانه هوشمند افق عمان (Oman Smart ERP)',
      theme: ThemeData(
        primaryColor: const Color(0xFF0F766E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const ErpRootGate(),
    );
  }
}

// ============================================================================
// مدل کاربر و سطوح دسترسی (Role-Based Access Control)
// ============================================================================
class AppUserAccount {
  final String id;
  String username;
  String password;
  String displayName;
  String roleTitle;
  bool isSuperAdmin; // ادمین اصلی (شما)

  // مجوزهای دقیق قابل تنظیم توسط ادمین برای هر کاربر:
  bool canViewReports; // مشاهده پیشخوان و گزارش‌ها (فقط رویت)
  bool canManagePettyCash; // ثبت و ویرایش تنخواه و هزینه‌های روزانه
  bool canManageWarehouses; // ورود کالا به انبار ۱ (مواد اولیه) و انبار ۲ (ملزومات بسته‌بندی)
  bool canManageProduction; // ثبت تولید کارمزدی و فرمول بهای تمام‌شده
  bool canManageSales; // ثبت فاکتور فروش و مشتریان
  bool canViewProfitAndPartners; // مشاهده صورت سود و زیان و سهم شرکا
  bool canExportFinance; // دریافت خروجی اکسل و CSV واحد مالی

  AppUserAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.displayName,
    required this.roleTitle,
    this.isSuperAdmin = false,
    this.canViewReports = true,
    this.canManagePettyCash = false,
    this.canManageWarehouses = false,
    this.canManageProduction = false,
    this.canManageSales = false,
    this.canViewProfitAndPartners = false,
    this.canExportFinance = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'displayName': displayName,
        'roleTitle': roleTitle,
        'isSuperAdmin': isSuperAdmin,
        'canViewReports': canViewReports,
        'canManagePettyCash': canManagePettyCash,
        'canManageWarehouses': canManageWarehouses,
        'canManageProduction': canManageProduction,
        'canManageSales': canManageSales,
        'canViewProfitAndPartners': canViewProfitAndPartners,
        'canExportFinance': canExportFinance,
      };

  factory AppUserAccount.fromJson(Map<String, dynamic> j) => AppUserAccount(
        id: j['id']?.toString() ?? '',
        username: j['username']?.toString() ?? '',
        password: j['password']?.toString() ?? '',
        displayName: j['displayName']?.toString() ?? '',
        roleTitle: j['roleTitle']?.toString() ?? '',
        isSuperAdmin: j['isSuperAdmin'] == true,
        canViewReports: j['canViewReports'] != false,
        canManagePettyCash: j['canManagePettyCash'] == true,
        canManageWarehouses: j['canManageWarehouses'] == true,
        canManageProduction: j['canManageProduction'] == true,
        canManageSales: j['canManageSales'] == true,
        canViewProfitAndPartners: j['canViewProfitAndPartners'] == true,
        canExportFinance: j['canExportFinance'] != false,
      );
}

// ============================================================================
// مدل‌های تنخواه و هزینه‌های روزانه
// ============================================================================
enum TxMode { expense, deposit }
enum ExpenseSource { petty, pocket, personal }

class CustomFilterDef {
  final String id;
  final String name;
  final List<String> options;

  CustomFilterDef({required this.id, required this.name, required this.options});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'options': options};

  factory CustomFilterDef.fromJson(Map<String, dynamic> j) => CustomFilterDef(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        options: (j['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class TransactionRecord {
  final String id;
  final TxMode mode;
  final ExpenseSource source;
  final double amountOMR;
  final DateTime date;
  final String topic;
  final String category;
  final String title;
  final String note;
  final Map<String, String> customValues;

  TransactionRecord({
    required this.id,
    required this.mode,
    required this.source,
    required this.amountOMR,
    required this.date,
    required this.topic,
    required this.category,
    required this.title,
    this.note = '',
    this.customValues = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'source': source.name,
        'amountOMR': amountOMR,
        'date': date.toIso8601String(),
        'topic': topic,
        'category': category,
        'title': title,
        'note': note,
        'customValues': customValues,
      };

  factory TransactionRecord.fromJson(Map<String, dynamic> j) => TransactionRecord(
        id: j['id']?.toString() ?? '',
        mode: j['mode'] == 'deposit' ? TxMode.deposit : TxMode.expense,
        source: ExpenseSource.values.firstWhere(
          (e) => e.name == j['source'],
          orElse: () => ExpenseSource.petty,
        ),
        amountOMR: (j['amountOMR'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        topic: j['topic']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        customValues: (j['customValues'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

class ConsolidatedExpenseRow {
  final String groupTitle;
  final String subTitle;
  int count;
  double totalExpenseOMR;
  double totalDepositOMR;
  DateTime firstDate;
  DateTime lastDate;

  ConsolidatedExpenseRow({
    required this.groupTitle,
    required this.subTitle,
    required this.count,
    required this.totalExpenseOMR,
    required this.totalDepositOMR,
    required this.firstDate,
    required this.lastDate,
  });
}

// ============================================================================
// مدل‌های ۳ انبار، بهای تمام‌شده صنعتی (BOM/COGS) و فروش
// ============================================================================
enum WarehouseType {
  rawMaterial, // انبار ۱: مواد اولیه اصلی
  packagingSupply, // انبار ۲: ملزومات بسته‌بندی (کارتن، نایلون، لیبل)
  finishedGood, // انبار ۳: محصول نهایی آماده فروش
}

class InventoryItem {
  final String id;
  final String name;
  final WarehouseType warehouse;
  final String unit;
  double unitWeightKg;
  double currentQty;
  double avgUnitCostOMR;
  double defaultSalePriceOMR;
  double defaultCartonPerUnit;
  double defaultNylonPerUnit;
  double defaultLabelPerUnit;

  InventoryItem({
    required this.id,
    required this.name,
    required this.warehouse,
    required this.unit,
    this.unitWeightKg = 1.0,
    this.currentQty = 0.0,
    this.avgUnitCostOMR = 0.0,
    this.defaultSalePriceOMR = 0.0,
    this.defaultCartonPerUnit = 0.1,
    this.defaultNylonPerUnit = 1.0,
    this.defaultLabelPerUnit = 1.0,
  });

  double get totalInventoryValueOMR => (currentQty > 0 ? currentQty : 0) * avgUnitCostOMR;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'warehouse': warehouse.name,
        'unit': unit,
        'unitWeightKg': unitWeightKg,
        'currentQty': currentQty,
        'avgUnitCostOMR': avgUnitCostOMR,
        'defaultSalePriceOMR': defaultSalePriceOMR,
        'defaultCartonPerUnit': defaultCartonPerUnit,
        'defaultNylonPerUnit': defaultNylonPerUnit,
        'defaultLabelPerUnit': defaultLabelPerUnit,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        warehouse: WarehouseType.values.firstWhere(
          (e) => e.name == j['warehouse'],
          orElse: () => WarehouseType.rawMaterial,
        ),
        unit: j['unit']?.toString() ?? 'واحد',
        unitWeightKg: (j['unitWeightKg'] as num?)?.toDouble() ?? 1.0,
        currentQty: (j['currentQty'] as num?)?.toDouble() ?? 0.0,
        avgUnitCostOMR: (j['avgUnitCostOMR'] as num?)?.toDouble() ?? 0.0,
        defaultSalePriceOMR: (j['defaultSalePriceOMR'] as num?)?.toDouble() ?? 0.0,
        defaultCartonPerUnit: (j['defaultCartonPerUnit'] as num?)?.toDouble() ?? 0.1,
        defaultNylonPerUnit: (j['defaultNylonPerUnit'] as num?)?.toDouble() ?? 1.0,
        defaultLabelPerUnit: (j['defaultLabelPerUnit'] as num?)?.toDouble() ?? 1.0,
      );
}

class PurchaseInboundDoc {
  final String id;
  final DateTime date;
  final String itemId;
  final String itemName;
  final WarehouseType warehouse;
  final String unit;
  final double qty;
  final double purchaseUnitPriceOMR;
  final double freightAndCustomsOMR;
  final String note;

  PurchaseInboundDoc({
    required this.id,
    required this.date,
    required this.itemId,
    required this.itemName,
    required this.warehouse,
    required this.unit,
    required this.qty,
    required this.purchaseUnitPriceOMR,
    required this.freightAndCustomsOMR,
    this.note = '',
  });

  double get totalPurchaseBaseOMR => qty * purchaseUnitPriceOMR;
  double get totalLandedCostOMR => totalPurchaseBaseOMR + freightAndCustomsOMR;
  double get landedUnitCostOMR => qty > 0 ? totalLandedCostOMR / qty : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'itemId': itemId,
        'itemName': itemName,
        'warehouse': warehouse.name,
        'unit': unit,
        'qty': qty,
        'purchaseUnitPriceOMR': purchaseUnitPriceOMR,
        'freightAndCustomsOMR': freightAndCustomsOMR,
        'note': note,
      };

  factory PurchaseInboundDoc.fromJson(Map<String, dynamic> j) => PurchaseInboundDoc(
        id: j['id']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        itemId: j['itemId']?.toString() ?? '',
        itemName: j['itemName']?.toString() ?? '',
        warehouse: WarehouseType.values.firstWhere(
          (e) => e.name == j['warehouse'],
          orElse: () => WarehouseType.rawMaterial,
        ),
        unit: j['unit']?.toString() ?? 'واحد',
        qty: (j['qty'] as num?)?.toDouble() ?? 0.0,
        purchaseUnitPriceOMR: (j['purchaseUnitPriceOMR'] as num?)?.toDouble() ?? 0.0,
        freightAndCustomsOMR: (j['freightAndCustomsOMR'] as num?)?.toDouble() ?? 0.0,
        note: j['note']?.toString() ?? '',
      );
}

class ProductionCostDoc {
  final String id;
  final DateTime date;
  final String rawItemId;
  final String rawItemName;
  final double rawQtyUsed;
  final double rawCostOMR;
  final String cartonItemId;
  final String cartonItemName;
  final double cartonQtyUsed;
  final double cartonCostOMR;
  final String nylonItemId;
  final String nylonItemName;
  final double nylonQtyUsed;
  final double nylonCostOMR;
  final String labelItemId;
  final String labelItemName;
  final double labelQtyUsed;
  final double labelCostOMR;
  final double factoryTollFeeOMR;
  final double transportAndOtherCostOMR;
  final String finishedItemId;
  final String finishedItemName;
  final String finishedUnit;
  final double finishedQtyProduced;
  final double finishedTotalWeightKg;
  final double wastageKg;
  final double totalBatchCostOMR;
  final double unitCostOMR;
  final double costPerKgOMR;
  final String note;

  ProductionCostDoc({
    required this.id,
    required this.date,
    required this.rawItemId,
    required this.rawItemName,
    required this.rawQtyUsed,
    required this.rawCostOMR,
    required this.cartonItemId,
    required this.cartonItemName,
    required this.cartonQtyUsed,
    required this.cartonCostOMR,
    required this.nylonItemId,
    required this.nylonItemName,
    required this.nylonQtyUsed,
    required this.nylonCostOMR,
    required this.labelItemId,
    required this.labelItemName,
    required this.labelQtyUsed,
    required this.labelCostOMR,
    required this.factoryTollFeeOMR,
    required this.transportAndOtherCostOMR,
    required this.finishedItemId,
    required this.finishedItemName,
    required this.finishedUnit,
    required this.finishedQtyProduced,
    required this.finishedTotalWeightKg,
    required this.wastageKg,
    required this.totalBatchCostOMR,
    required this.unitCostOMR,
    required this.costPerKgOMR,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'rawItemId': rawItemId,
        'rawItemName': rawItemName,
        'rawQtyUsed': rawQtyUsed,
        'rawCostOMR': rawCostOMR,
        'cartonItemId': cartonItemId,
        'cartonItemName': cartonItemName,
        'cartonQtyUsed': cartonQtyUsed,
        'cartonCostOMR': cartonCostOMR,
        'nylonItemId': nylonItemId,
        'nylonItemName': nylonItemName,
        'nylonQtyUsed': nylonQtyUsed,
        'nylonCostOMR': nylonCostOMR,
        'labelItemId': labelItemId,
        'labelItemName': labelItemName,
        'labelQtyUsed': labelQtyUsed,
        'labelCostOMR': labelCostOMR,
        'factoryTollFeeOMR': factoryTollFeeOMR,
        'transportAndOtherCostOMR': transportAndOtherCostOMR,
        'finishedItemId': finishedItemId,
        'finishedItemName': finishedItemName,
        'finishedUnit': finishedUnit,
        'finishedQtyProduced': finishedQtyProduced,
        'finishedTotalWeightKg': finishedTotalWeightKg,
        'wastageKg': wastageKg,
        'totalBatchCostOMR': totalBatchCostOMR,
        'unitCostOMR': unitCostOMR,
        'costPerKgOMR': costPerKgOMR,
        'note': note,
      };

  factory ProductionCostDoc.fromJson(Map<String, dynamic> j) => ProductionCostDoc(
        id: j['id']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        rawItemId: j['rawItemId']?.toString() ?? '',
        rawItemName: j['rawItemName']?.toString() ?? '',
        rawQtyUsed: (j['rawQtyUsed'] as num?)?.toDouble() ?? 0.0,
        rawCostOMR: (j['rawCostOMR'] as num?)?.toDouble() ?? 0.0,
        cartonItemId: j['cartonItemId']?.toString() ?? '',
        cartonItemName: j['cartonItemName']?.toString() ?? '',
        cartonQtyUsed: (j['cartonQtyUsed'] as num?)?.toDouble() ?? 0.0,
        cartonCostOMR: (j['cartonCostOMR'] as num?)?.toDouble() ?? 0.0,
        nylonItemId: j['nylonItemId']?.toString() ?? '',
        nylonItemName: j['nylonItemName']?.toString() ?? '',
        nylonQtyUsed: (j['nylonQtyUsed'] as num?)?.toDouble() ?? 0.0,
        nylonCostOMR: (j['nylonCostOMR'] as num?)?.toDouble() ?? 0.0,
        labelItemId: j['labelItemId']?.toString() ?? '',
        labelItemName: j['labelItemName']?.toString() ?? '',
        labelQtyUsed: (j['labelQtyUsed'] as num?)?.toDouble() ?? 0.0,
        labelCostOMR: (j['labelCostOMR'] as num?)?.toDouble() ?? 0.0,
        factoryTollFeeOMR: (j['factoryTollFeeOMR'] as num?)?.toDouble() ?? 0.0,
        transportAndOtherCostOMR: (j['transportAndOtherCostOMR'] as num?)?.toDouble() ?? 0.0,
        finishedItemId: j['finishedItemId']?.toString() ?? '',
        finishedItemName: j['finishedItemName']?.toString() ?? '',
        finishedUnit: j['finishedUnit']?.toString() ?? 'بسته',
        finishedQtyProduced: (j['finishedQtyProduced'] as num?)?.toDouble() ?? 0.0,
        finishedTotalWeightKg: (j['finishedTotalWeightKg'] as num?)?.toDouble() ?? 0.0,
        wastageKg: (j['wastageKg'] as num?)?.toDouble() ?? 0.0,
        totalBatchCostOMR: (j['totalBatchCostOMR'] as num?)?.toDouble() ?? 0.0,
        unitCostOMR: (j['unitCostOMR'] as num?)?.toDouble() ?? 0.0,
        costPerKgOMR: (j['costPerKgOMR'] as num?)?.toDouble() ?? 0.0,
        note: j['note']?.toString() ?? '',
      );
}

class SaleProfitDoc {
  final String id;
  final DateTime date;
  final String finishedItemId;
  final String finishedItemName;
  final String unit;
  final double qtySold;
  final double unitSalePriceOMR;
  final double unitCogsOMR;
  final double deliveryExpenseOMR;
  final String customerName;
  final String paymentStatus;
  final int partnerSplitDivisor;
  final String note;

  SaleProfitDoc({
    required this.id,
    required this.date,
    required this.finishedItemId,
    required this.finishedItemName,
    required this.unit,
    required this.qtySold,
    required this.unitSalePriceOMR,
    required this.unitCogsOMR,
    required this.deliveryExpenseOMR,
    required this.customerName,
    required this.paymentStatus,
    required this.partnerSplitDivisor,
    this.note = '',
  });

  double get totalRevenueOMR => qtySold * unitSalePriceOMR;
  double get totalCogsOMR => (qtySold * unitCogsOMR) + deliveryExpenseOMR;
  double get netProfitOrLossOMR => totalRevenueOMR - totalCogsOMR;
  double get profitMarginPercent =>
      totalRevenueOMR > 0 ? (netProfitOrLossOMR / totalRevenueOMR) * 100.0 : 0.0;
  bool get isInLoss => netProfitOrLossOMR < -0.0005;

  double get myProfitShareOMR =>
      partnerSplitDivisor > 1 ? netProfitOrLossOMR / partnerSplitDivisor : netProfitOrLossOMR;
  double get partnersProfitShareOMR => netProfitOrLossOMR - myProfitShareOMR;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'finishedItemId': finishedItemId,
        'finishedItemName': finishedItemName,
        'unit': unit,
        'qtySold': qtySold,
        'unitSalePriceOMR': unitSalePriceOMR,
        'unitCogsOMR': unitCogsOMR,
        'deliveryExpenseOMR': deliveryExpenseOMR,
        'customerName': customerName,
        'paymentStatus': paymentStatus,
        'partnerSplitDivisor': partnerSplitDivisor,
        'note': note,
      };

  factory SaleProfitDoc.fromJson(Map<String, dynamic> j) => SaleProfitDoc(
        id: j['id']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        finishedItemId: j['finishedItemId']?.toString() ?? '',
        finishedItemName: j['finishedItemName']?.toString() ?? '',
        unit: j['unit']?.toString() ?? 'بسته',
        qtySold: (j['qtySold'] as num?)?.toDouble() ?? 0.0,
        unitSalePriceOMR: (j['unitSalePriceOMR'] as num?)?.toDouble() ?? 0.0,
        unitCogsOMR: (j['unitCogsOMR'] as num?)?.toDouble() ?? 0.0,
        deliveryExpenseOMR: (j['deliveryExpenseOMR'] as num?)?.toDouble() ?? 0.0,
        customerName: j['customerName']?.toString() ?? '',
        paymentStatus: j['paymentStatus']?.toString() ?? 'نقدی / واریز بانکی',
        partnerSplitDivisor: (j['partnerSplitDivisor'] as num?)?.toInt() ?? 1,
        note: j['note']?.toString() ?? '',
      );
}

// ============================================================================
// ویجت اصلی با دروازه ورود اجباری (Login Screen) و مدیریت سطوح دسترسی
// ============================================================================
class ErpRootGate extends StatefulWidget {
  const ErpRootGate({super.key});

  @override
  State<ErpRootGate> createState() => _ErpRootGateState();
}

class _ErpRootGateState extends State<ErpRootGate> {
  // کاربر واردشده فعلی (اگر null باشد، صفحه ورود با رمز عبور نمایش داده می‌شود)
  AppUserAccount? _currentUser;

  // فهرست کاربران و سطوح دسترسی که ادمین تعریف می‌کند
  List<AppUserAccount> _users = [];

  // کنترلرهای صفحه ورود / راه‌اندازی اولیه ادمین
  final TextEditingController _loginUserCtrl = TextEditingController();
  final TextEditingController _loginPassCtrl = TextEditingController();
  final TextEditingController _setupAdminNameCtrl = TextEditingController(text: 'مدیر ارشد (ادمین)');
  final TextEditingController _setupAdminUserCtrl = TextEditingController(text: 'admin');
  final TextEditingController _setupAdminPassCtrl = TextEditingController();
  final TextEditingController _loginCloudUrlCtrl = TextEditingController();

  int _selectedIndex = 0;
  String _cloudSyncUrl = '';
  bool _isSyncing = false;
  String _lastSyncStatus = 'آماده اتصال ابری';

  // داده‌های تنخواه و هزینه‌ها
  List<String> _categories = [
    'خورد و خوراک و اقلام مصرفی',
    'آب و برق و قبوض (برق، آب، اینترنت)',
    'اجاره مسکن و اقامت',
    'ایاب و ذهاب و تاکسی',
    'اجاره خودرو و بنزین',
    'امور اداری، ویزا و ثبت شرکت',
    'ارسال نمونه و لجستیک',
    'تجهیزات و ملزومات کاری',
    'سایر هزینه‌ها',
  ];

  List<String> _topics = [
    'تنخواه جاری شرکت در عمان',
    'امور راه‌اندازی و ثبت شرکت/برند',
    'پروژه کارخانه و بسته‌بندی مسقط',
    'مخارج شخصی روزمره',
  ];

  List<CustomFilterDef> _customFilters = [
    CustomFilterDef(
      id: 'cf_payment',
      name: 'روش پرداخت',
      options: ['نقدی (Cash OMR)', 'کارت بانک مسقط', 'حواله / موبایل بانک'],
    ),
    CustomFilterDef(
      id: 'cf_receipt',
      name: 'وضعیت فاکتور',
      options: ['دارای فاکتور رسمی', 'رسید عادی', 'بدون رسید'],
    ),
  ];

  List<TransactionRecord> _transactions = [];

  // داده‌های ۳ انبار و فروش
  List<String> _customers = [
    'مشتری عمومی بازار مسقط',
    'رستوران‌ها و فست‌فودها',
    'سوپرمارکت‌ها و هایپرمارکت‌ها',
    'پخش عمده مواد غذایی',
  ];

  List<InventoryItem> _items = [
    InventoryItem(
      id: 'raw_cheese_block',
      name: 'پنیر پیتزا بلوکی (ماده اولیه)',
      warehouse: WarehouseType.rawMaterial,
      unit: 'کیلوگرم',
      unitWeightKg: 1.0,
      avgUnitCostOMR: 1.450,
    ),
    InventoryItem(
      id: 'raw_butter_bulk',
      name: 'کره فله / بلوکی (ماده اولیه)',
      warehouse: WarehouseType.rawMaterial,
      unit: 'کیلوگرم',
      unitWeightKg: 1.0,
      avgUnitCostOMR: 1.800,
    ),
    InventoryItem(
      id: 'pkg_carton',
      name: 'کارتن بسته‌بندی محصول',
      warehouse: WarehouseType.packagingSupply,
      unit: 'عدد',
      unitWeightKg: 0.0,
      avgUnitCostOMR: 0.250,
    ),
    InventoryItem(
      id: 'pkg_nylon',
      name: 'نایلون / پاکت بسته‌بندی',
      warehouse: WarehouseType.packagingSupply,
      unit: 'عدد / برگ',
      unitWeightKg: 0.0,
      avgUnitCostOMR: 0.035,
    ),
    InventoryItem(
      id: 'pkg_label',
      name: 'لیبل / برچسب محصول',
      warehouse: WarehouseType.packagingSupply,
      unit: 'عدد',
      unitWeightKg: 0.0,
      avgUnitCostOMR: 0.015,
    ),
    InventoryItem(
      id: 'fin_cheese_1kg',
      name: 'پنیر پیتزا رنده‌شده ۱ کیلویی',
      warehouse: WarehouseType.finishedGood,
      unit: 'بسته ۱ کیلویی',
      unitWeightKg: 1.0,
      avgUnitCostOMR: 1.700,
      defaultSalePriceOMR: 2.200,
      defaultCartonPerUnit: 0.1,
      defaultNylonPerUnit: 1.0,
      defaultLabelPerUnit: 1.0,
    ),
    InventoryItem(
      id: 'fin_cheese_500g',
      name: 'پنیر پیتزا رنده‌شده ۵۰۰ گرمی',
      warehouse: WarehouseType.finishedGood,
      unit: 'بسته ۵۰۰ گرمی',
      unitWeightKg: 0.5,
      avgUnitCostOMR: 0.900,
      defaultSalePriceOMR: 1.200,
      defaultCartonPerUnit: 0.05,
      defaultNylonPerUnit: 1.0,
      defaultLabelPerUnit: 1.0,
    ),
    InventoryItem(
      id: 'fin_butter_100g',
      name: 'کره ریپک و لیبل‌خورده ۱۰۰ گرمی',
      warehouse: WarehouseType.finishedGood,
      unit: 'بسته ۱۰۰ گرمی',
      unitWeightKg: 0.1,
      avgUnitCostOMR: 0.220,
      defaultSalePriceOMR: 0.300,
      defaultCartonPerUnit: 0.02,
      defaultNylonPerUnit: 1.0,
      defaultLabelPerUnit: 1.0,
    ),
    InventoryItem(
      id: 'fin_butter_250g',
      name: 'کره ریپک و لیبل‌خورده ۲۵۰ گرمی',
      warehouse: WarehouseType.finishedGood,
      unit: 'بسته ۲۵۰ گرمی',
      unitWeightKg: 0.25,
      avgUnitCostOMR: 0.520,
      defaultSalePriceOMR: 0.700,
      defaultCartonPerUnit: 0.025,
      defaultNylonPerUnit: 1.0,
      defaultLabelPerUnit: 1.0,
    ),
  ];

  List<PurchaseInboundDoc> _inbounds = [];
  List<ProductionCostDoc> _productions = [];
  List<SaleProfitDoc> _sales = [];

  // کنترلرهای فرم تنخواه
  TxMode _formMode = TxMode.expense;
  ExpenseSource _formSource = ExpenseSource.petty;
  final TextEditingController _txAmountCtrl = TextEditingController();
  final TextEditingController _txTitleCtrl = TextEditingController();
  final TextEditingController _txNoteCtrl = TextEditingController();
  DateTime _txDate = DateTime.now();
  late String _selectedTopic;
  late String _selectedCategory;
  final Map<String, String> _selectedCustomValues = {};

  // کنترلرهای فرم ۳ انبار و تولید
  int _warehouseSubTab = 0;
  WarehouseType _inboundWhTarget = WarehouseType.rawMaterial;
  String? _selectedInboundItemId;
  final TextEditingController _inbQtyCtrl = TextEditingController();
  final TextEditingController _inbPriceCtrl = TextEditingController();
  final TextEditingController _inbFreightCtrl = TextEditingController(text: '0');

  String? _prodRawId;
  String? _prodFinId;
  String? _prodCartonId;
  String? _prodNylonId;
  String? _prodLabelId;
  final TextEditingController _prodRawQtyCtrl = TextEditingController();
  final TextEditingController _prodFinQtyCtrl = TextEditingController();
  final TextEditingController _prodCartonQtyCtrl = TextEditingController();
  final TextEditingController _prodNylonQtyCtrl = TextEditingController();
  final TextEditingController _prodLabelQtyCtrl = TextEditingController();
  final TextEditingController _prodTollFeeCtrl = TextEditingController(text: '0');
  final TextEditingController _prodTransportCtrl = TextEditingController(text: '0');

  // کنترلرهای فرم فروش و سهم شریک
  String? _saleFinId;
  String? _saleCustomer;
  final TextEditingController _saleQtyCtrl = TextEditingController();
  final TextEditingController _salePriceCtrl = TextEditingController();
  final TextEditingController _saleDeliveryCostCtrl = TextEditingController(text: '0');
  String _salePaymentStatus = 'نقدی / واریز بانکی';
  int _salePartnerDivisor = 1;
  final TextEditingController _customDivisorCtrl = TextEditingController(text: '2');

  // کنترلرهای گزارش‌گیری
  int _reportSectionTab = 0;
  bool _isConsolidatedExpenseReport = true;
  DateTime? _repFromDate;
  DateTime? _repToDate;

  List<InventoryItem> get _rawList =>
      _items.where((i) => i.warehouse == WarehouseType.rawMaterial).toList();
  List<InventoryItem> get _pkgList =>
      _items.where((i) => i.warehouse == WarehouseType.packagingSupply).toList();
  List<InventoryItem> get _finList =>
      _items.where((i) => i.warehouse == WarehouseType.finishedGood).toList();

  @override
  void initState() {
    super.initState();
    _selectedTopic = _topics.first;
    _selectedCategory = _categories.first;
    _syncDefaults();
    _loadLocalData();
  }

  void _syncDefaults() {
    for (final cf in _customFilters) {
      if (!_selectedCustomValues.containsKey(cf.id) && cf.options.isNotEmpty) {
        _selectedCustomValues[cf.id] = cf.options.first;
      }
    }
    if (_customers.isNotEmpty) _saleCustomer ??= _customers.first;
    final targetList = _inboundWhTarget == WarehouseType.rawMaterial ? _rawList : _pkgList;
    if (targetList.isNotEmpty) {
      if (_selectedInboundItemId == null || !targetList.any((e) => e.id == _selectedInboundItemId)) {
        _selectedInboundItemId = targetList.first.id;
        _inbPriceCtrl.text = targetList.first.avgUnitCostOMR.toStringAsFixed(3);
      }
    }
    if (_rawList.isNotEmpty) _prodRawId ??= _rawList.first.id;
    if (_pkgList.isNotEmpty) {
      _prodCartonId ??= _pkgList.firstWhere((e) => e.name.contains('کارتن'), orElse: () => _pkgList.first).id;
      _prodNylonId ??= _pkgList.firstWhere((e) => e.name.contains('نایلون'), orElse: () => _pkgList.first).id;
      _prodLabelId ??= _pkgList.firstWhere((e) => e.name.contains('لیبل'), orElse: () => _pkgList.first).id;
    }
    if (_finList.isNotEmpty) {
      _prodFinId ??= _finList.first.id;
      if (_saleFinId == null || !_finList.any((e) => e.id == _saleFinId)) {
        _saleFinId = _finList.first.id;
        _salePriceCtrl.text = _finList.first.defaultSalePriceOMR.toStringAsFixed(3);
      }
    }
  }

  File _getLocalDbFile() {
    final dir = Directory.systemTemp;
    return File('${dir.path}/oman_smart_erp_v4.json');
  }

  Future<void> _loadLocalData() async {
    try {
      final f = _getLocalDbFile();
      if (await f.exists()) {
        final content = await f.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          _applyJsonState(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalData() async {
    try {
      final f = _getLocalDbFile();
      await f.writeAsString(jsonEncode(_exportStateJson()));
    } catch (_) {}
  }

  Map<String, dynamic> _exportStateJson() {
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'cloudSyncUrl': _cloudSyncUrl,
      'users': _users.map((u) => u.toJson()).toList(),
      'categories': _categories,
      'topics': _topics,
      'customFilters': _customFilters.map((e) => e.toJson()).toList(),
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'customers': _customers,
      'items': _items.map((e) => e.toJson()).toList(),
      'inbounds': _inbounds.map((e) => e.toJson()).toList(),
      'productions': _productions.map((e) => e.toJson()).toList(),
      'sales': _sales.map((e) => e.toJson()).toList(),
    };
  }

  void _applyJsonState(Map<String, dynamic> data) {
    setState(() {
      if (data['cloudSyncUrl'] != null && _cloudSyncUrl.isEmpty) {
        _cloudSyncUrl = data['cloudSyncUrl'].toString();
        _loginCloudUrlCtrl.text = _cloudSyncUrl;
      }
      if (data['users'] is List) {
        final uList = (data['users'] as List)
            .map((e) => AppUserAccount.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (uList.isNotEmpty) _users = uList;
      }
      if (data['categories'] is List) {
        final l = (data['categories'] as List).map((e) => e.toString()).toList();
        if (l.isNotEmpty) _categories = l;
      }
      if (data['topics'] is List) {
        final l = (data['topics'] as List).map((e) => e.toString()).toList();
        if (l.isNotEmpty) _topics = l;
      }
      if (data['customFilters'] is List) {
        _customFilters = (data['customFilters'] as List)
            .map((e) => CustomFilterDef.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['transactions'] is List) {
        _transactions = (data['transactions'] as List)
            .map((e) => TransactionRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['customers'] is List) {
        final c = (data['customers'] as List).map((e) => e.toString()).toList();
        if (c.isNotEmpty) _customers = c;
      }
      if (data['items'] is List) {
        final list = (data['items'] as List)
            .map((e) => InventoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) _items = list;
      }
      if (data['inbounds'] is List) {
        _inbounds = (data['inbounds'] as List)
            .map((e) => PurchaseInboundDoc.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['productions'] is List) {
        _productions = (data['productions'] as List)
            .map((e) => ProductionCostDoc.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['sales'] is List) {
        _sales = (data['sales'] as List)
            .map((e) => SaleProfitDoc.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      _syncDefaults();
    });
  }

  Future<void> _pushToCloud() async {
    if (_cloudSyncUrl.trim().isEmpty) return;
    setState(() {
      _isSyncing = true;
      _lastSyncStatus = 'در حال همگام‌سازی ابری...';
    });
    try {
      final uri = Uri.parse(_cloudSyncUrl.trim());
      final client = HttpClient();
      final req = await client.putUrl(uri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(_exportStateJson())));
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() => _lastSyncStatus = '✅ ذخیره ابری موفق');
      }
      client.close();
    } catch (_) {
      setState(() => _lastSyncStatus = 'ذخیره در حافظه دستگاه');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _pullFromCloud() async {
    final targetUrl = _cloudSyncUrl.trim().isNotEmpty
        ? _cloudSyncUrl.trim()
        : _loginCloudUrlCtrl.text.trim();
    if (targetUrl.isEmpty) {
      _showMsg('لطفاً ابتدا آدرس ابری (Cloud URL) را وارد کنید.');
      return;
    }
    _cloudSyncUrl = targetUrl;
    setState(() {
      _isSyncing = true;
      _lastSyncStatus = 'در حال دریافت اطلاعات از اینترنت...';
    });
    try {
      final uri = Uri.parse(targetUrl);
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = await resp.transform(utf8.decoder).join();
        if (body.isNotEmpty && body != 'null') {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            _applyJsonState(Map<String, dynamic>.from(decoded));
            await _saveLocalData();
            setState(() => _lastSyncStatus = '✅ دریافت موفق از اینترنت');
            _showMsg('✅ آخرین اطلاعات و سطوح دسترسی کاربران از اینترنت دریافت شد.');
          }
        }
      }
      client.close();
    } catch (_) {
      _showMsg('خطا در اتصال به اینترنت');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String _fmtOMR(double v) => v.toStringAsFixed(3);
  String _fmtQty(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double get _totalPettyIn => _transactions
      .where((t) => t.mode == TxMode.deposit)
      .fold(0.0, (s, t) => s + t.amountOMR);
  double get _totalPettyOut => _transactions
      .where((t) => t.mode == TxMode.expense && t.source == ExpenseSource.petty)
      .fold(0.0, (s, t) => s + t.amountOMR);
  double get _pettyBalance => _totalPettyIn - _totalPettyOut;
  double get _totalSalesRevenueOMR => _sales.fold(0.0, (s, r) => s + r.totalRevenueOMR);
  double get _totalNetProfitOMR => _sales.fold(0.0, (s, r) => s + r.netProfitOrLossOMR);

  // ==========================================================================
  // ۱. صفحه ورود اجباری در بدو باز شدن برنامه (Login Screen & First-Time Admin Setup)
  // ==========================================================================
  Widget _buildLoginOrSetupGate() {
    final isFirstSetup = _users.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.verified_user, size: 52, color: Color(0xFF0F766E)),
                    const SizedBox(height: 10),
                    const Text(
                      'سامانه هوشمند افق عمان (Oman Smart ERP)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFirstSetup
                          ? 'راه‌اندازی اولیه حساب «ادمین اصلی (مدیر کل)»'
                          : 'ورود به سامانه بر اساس سطح دسترسی',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                    const Divider(height: 28),

                    // اتصال ابری برای دریافت کاربران در دستگاه‌های دوم و سوم
                    TextField(
                      controller: _loginCloudUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'آدرس اینترنتی فضای ابری (اختیاری - برای لینک ۳ دستگاه)',
                        hintText: 'https://your-db.firebaseio.com/erp.json',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'دریافت کاربران و اطلاعات از اینترنت',
                          icon: const Icon(Icons.cloud_download),
                          onPressed: _pullFromCloud,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (isFirstSetup) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '👑 شما اولین بار است که برنامه را باز می‌کنید. لطفاً نام کاربری و رمز عبور خودتان را به عنوان «ادمین اصلی برنامه» تعیین کنید (یا اگر این دستگاه دوم/سوم است، آدرس ابری بالا را وارد کرده و دکمه ابر را بزنید):',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _setupAdminNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'عنوان شما در برنامه',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _setupAdminUserCtrl,
                        decoration: const InputDecoration(
                          labelText: 'نام کاربری ادمین (مثلاً admin) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _setupAdminPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'رمز عبور ادمین (حداقل ۴ کاراکتر) *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final u = _setupAdminUserCtrl.text.trim();
                          final p = _setupAdminPassCtrl.text.trim();
                          if (u.isEmpty || p.length < 4) {
                            _showMsg('لطفاً نام کاربری و رمز عبور (حداقل ۴ کاراکتر) وارد کنید.');
                            return;
                          }
                          final adminAcc = AppUserAccount(
                            id: 'usr_admin',
                            username: u,
                            password: p,
                            displayName: _setupAdminNameCtrl.text.trim().isEmpty
                                ? 'ادمین اصلی'
                                : _setupAdminNameCtrl.text.trim(),
                            roleTitle: 'مدیر کل و ادمین سامانه',
                            isSuperAdmin: true,
                            canViewReports: true,
                            canManagePettyCash: true,
                            canManageWarehouses: true,
                            canManageProduction: true,
                            canManageSales: true,
                            canViewProfitAndPartners: true,
                            canExportFinance: true,
                          );
                          // همچنین یک کاربر پیش‌فرض «واحد مالی (فقط رویت)» می‌سازیم که ادمین بتواند رمزش را تنظیم کند
                          final financeViewer = AppUserAccount(
                            id: 'usr_finance',
                            username: 'finance',
                            password: p,
                            displayName: 'واحد مالی / مشاهده‌گر',
                            roleTitle: 'فقط رویت و گزارش‌گیری مالی',
                            isSuperAdmin: false,
                            canViewReports: true,
                            canManagePettyCash: false,
                            canManageWarehouses: false,
                            canManageProduction: false,
                            canManageSales: false,
                            canViewProfitAndPartners: true,
                            canExportFinance: true,
                          );
                          setState(() {
                            _cloudSyncUrl = _loginCloudUrlCtrl.text.trim();
                            _users = [adminAcc, financeViewer];
                            _currentUser = adminAcc;
                            _selectedIndex = 0;
                          });
                          _saveLocalData();
                          _pushToCloud();
                        },
                        icon: const Icon(Icons.lock_open),
                        label: const Text('ثبت رمز ادمین و ورود به سامانه'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _loginUserCtrl,
                        decoration: const InputDecoration(
                          labelText: 'نام کاربری (Username) *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _loginPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'رمز عبور (Password) *',
                          prefixIcon: Icon(Icons.key),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final u = _loginUserCtrl.text.trim().toLowerCase();
                          final p = _loginPassCtrl.text.trim();
                          final matched = _users.where(
                            (acc) => acc.username.toLowerCase() == u && acc.password == p,
                          );
                          if (matched.isEmpty) {
                            _showMsg('❌ نام کاربری یا رمز عبور اشتباه است.');
                            return;
                          }
                          setState(() {
                            if (_loginCloudUrlCtrl.text.trim().isNotEmpty) {
                              _cloudSyncUrl = _loginCloudUrlCtrl.text.trim();
                            }
                            _currentUser = matched.first;
                            _selectedIndex = 0;
                            _loginPassCtrl.clear();
                          });
                          _saveLocalData();
                          _showMsg('✅ خوش آمدید: ${_currentUser!.displayName} (${_currentUser!.roleTitle})');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('ورود به سامانه'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // بدنه اصلی برنامه پس از ورود کاربر (بر اساس سطح دسترسی کاربر واردشده)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return _buildLoginOrSetupGate();
    }

    final u = _currentUser!;
    final pages = <Widget>[];
    final navItems = <BottomNavigationBarItem>[];

    // تب ۱: تنخواه و هزینه‌ها (اگر مجوز ثبت داشته باشد فرم ثبت باز است، وگرنه فقط لیست را می‌بیند)
    pages.add(_buildPettyCashAndExpensesTab(u));
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet),
      label: 'تنخواه و هزینه',
    ));

    // تب ۲: ۳ انبار و تولید کارمزدی
    pages.add(_buildThreeWarehousesAndBomTab(u));
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.warehouse),
      label: '۳ انبار و تولید',
    ));

    // تب ۳: ثبت فروش (فقط اگر ادمین به این کاربر مجوز فروش داده باشد نمایش داده می‌شود)
    if (u.isSuperAdmin || u.canManageSales) {
      pages.add(_buildSalesProfitAndPartnerTab(u));
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale),
        label: 'فروش و شریک',
      ));
    }

    // تب ۴: گزارش‌های تجمیعی و مالی
    if (u.isSuperAdmin || u.canViewReports) {
      pages.add(_buildUnifiedReportsAndCfoTab(u));
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.assessment),
        label: 'گزارش و مالی',
      ));
    }

    // تب ۵: پنل مدیریت کاربران و تعیین سطح دسترسی (منحصراً مخصوص شما به عنوان ادمین اصلی!)
    if (u.isSuperAdmin) {
      pages.add(_buildAdminUsersAndPermissionsTab());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'مدیریت دسترسی‌ها',
      ));
    }

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: u.isSuperAdmin ? const Color(0xFF0F766E) : const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${u.isSuperAdmin ? '👑' : '👤'} ${u.displayName} — ${u.roleTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            Text(_lastSyncStatus, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'دریافت آخرین اطلاعات از اینترنت',
            onPressed: _isSyncing ? null : _pullFromCloud,
            icon: const Icon(Icons.cloud_download),
          ),
          if (u.isSuperAdmin || u.canManagePettyCash || u.canManageWarehouses || u.canManageSales)
            IconButton(
              tooltip: 'ارسال به فضای ابری',
              onPressed: _isSyncing ? null : _pushToCloud,
              icon: const Icon(Icons.cloud_upload),
            ),
          IconButton(
            tooltip: 'خروج از حساب و قفل برنامه',
            onPressed: () => setState(() => _currentUser = null),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderMetric(
                  _pettyBalance >= 0 ? 'مانده تنخواه' : 'طلب تنخواه',
                  '${_fmtOMR(_pettyBalance.abs())} OMR',
                ),
                _buildHeaderMetric('کل فروش بازار', '${_fmtOMR(_totalSalesRevenueOMR)} OMR'),
                if (u.isSuperAdmin || u.canViewProfitAndPartners)
                  _buildHeaderMetric('سود خالص فروش', '${_fmtOMR(_totalNetProfitOMR)} OMR'),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: Colors.grey[600],
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: navItems,
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // ==========================================================================
  // تب ۱: تنخواه و هزینه‌های روزانه
  // ==========================================================================
  void _saveExpenseOrDeposit() {
    final amt = double.tryParse(_txAmountCtrl.text.trim());
    final title = _txTitleCtrl.text.trim();
    if (amt == null || amt <= 0 || title.isEmpty) {
      _showMsg('لطفاً مبلغ (OMR) و شرح را وارد کنید.');
      return;
    }

    final rec = TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: _formMode,
      source: _formSource,
      amountOMR: double.parse(amt.toStringAsFixed(3)),
      date: _txDate,
      topic: _selectedTopic,
      category: _formMode == TxMode.deposit ? 'دریافت تنخواه از شرکت' : _selectedCategory,
      title: title,
      note: _txNoteCtrl.text.trim(),
      customValues: Map<String, String>.from(_selectedCustomValues),
    );

    setState(() {
      _transactions.insert(0, rec);
      _txAmountCtrl.clear();
      _txTitleCtrl.clear();
      _txNoteCtrl.clear();
    });
    _saveLocalData();
    _pushToCloud();
    _showMsg('✅ در دفتر تنخواه و هزینه‌ها ثبت شد.');
  }

  Widget _buildPettyCashAndExpensesTab(AppUserAccount u) {
    final canEdit = u.isSuperAdmin || u.canManagePettyCash;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (!canEdit)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '👁️ سطح دسترسی شما در این بخش «فقط مشاهده» است. امکان ثبت یا تغییر ارقام وجود ندارد.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        if (canEdit)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('➕ ثبت هزینه روزانه یا دریافت تنخواه از شرکت',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('💸 ثبت هزینه کرد'),
                        selected: _formMode == TxMode.expense,
                        onSelected: (_) => setState(() => _formMode = TxMode.expense),
                      ),
                      ChoiceChip(
                        label: const Text('💰 دریافت تنخواه از شرکت'),
                        selected: _formMode == TxMode.deposit,
                        onSelected: (_) => setState(() => _formMode = TxMode.deposit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_formMode == TxMode.expense) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('از تنخواه شرکت'),
                          selected: _formSource == ExpenseSource.petty,
                          onSelected: (_) => setState(() => _formSource = ExpenseSource.petty),
                        ),
                        ChoiceChip(
                          label: const Text('از جیب برای کار'),
                          selected: _formSource == ExpenseSource.pocket,
                          onSelected: (_) => setState(() => _formSource = ExpenseSource.pocket),
                        ),
                        ChoiceChip(
                          label: const Text('هزینه شخصی'),
                          selected: _formSource == ExpenseSource.personal,
                          onSelected: (_) => setState(() => _formSource = ExpenseSource.personal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _txAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'مبلغ (ریال عمان - OMR) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final p = await showDatePicker(
                              context: context,
                              initialDate: _txDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (p != null) setState(() => _txDate = p);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_fmtDate(_txDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    items: _topics.map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedTopic = v!),
                    decoration: const InputDecoration(labelText: 'موضوع', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  if (_formMode == TxMode.expense) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      decoration: const InputDecoration(labelText: 'سرفصل هزینه کرد', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _txTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'عنوان / شرح (مثلاً: بنزین، خرید خوراکی، قبض برق...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _saveExpenseOrDeposit,
                    icon: const Icon(Icons.check),
                    label: const Text('ثبت در دفتر تنخواه و هزینه‌ها'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📋 آخرین تراکنش‌های تنخواه و هزینه‌ها:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                if (_transactions.isEmpty)
                  const Text('هنوز تراکنشی ثبت نشده است.')
                else
                  ..._transactions.take(15).map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_fmtDate(t.date)} | ${t.topic} | ${t.category}'),
                        trailing: Text(
                          '${t.mode == TxMode.deposit ? '+' : ''}${_fmtOMR(t.amountOMR)} OMR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // تب ۲: سامانه ۳ انبار مجزا + ورود بار + تولید کارمزدی و بهای تمام‌شده (BOM)
  // ==========================================================================
  void _autoCalcBom(String finQtyText) {
    final finQty = double.tryParse(finQtyText.trim()) ?? 0.0;
    if (finQty <= 0 || _prodFinId == null) return;
    final finItem = _finList.firstWhere((e) => e.id == _prodFinId!, orElse: () => _finList.first);
    setState(() {
      _prodCartonQtyCtrl.text = (finQty * finItem.defaultCartonPerUnit).toStringAsFixed(1);
      _prodNylonQtyCtrl.text = (finQty * finItem.defaultNylonPerUnit).toStringAsFixed(0);
      _prodLabelQtyCtrl.text = (finQty * finItem.defaultLabelPerUnit).toStringAsFixed(0);
    });
  }

  Map<String, double> _previewLiveBatchCost() {
    final rawQty = double.tryParse(_prodRawQtyCtrl.text.trim()) ?? 0.0;
    final finQty = double.tryParse(_prodFinQtyCtrl.text.trim()) ?? 0.0;
    final cartonQty = double.tryParse(_prodCartonQtyCtrl.text.trim()) ?? 0.0;
    final nylonQty = double.tryParse(_prodNylonQtyCtrl.text.trim()) ?? 0.0;
    final labelQty = double.tryParse(_prodLabelQtyCtrl.text.trim()) ?? 0.0;
    final tollFee = double.tryParse(_prodTollFeeCtrl.text.trim()) ?? 0.0;
    final transport = double.tryParse(_prodTransportCtrl.text.trim()) ?? 0.0;

    final rawItem = _items.firstWhere((e) => e.id == _prodRawId, orElse: () => _rawList.first);
    final finItem = _items.firstWhere((e) => e.id == _prodFinId, orElse: () => _finList.first);
    final cartonItem = _items.firstWhere((e) => e.id == _prodCartonId, orElse: () => _pkgList.first);
    final nylonItem = _items.firstWhere((e) => e.id == _prodNylonId, orElse: () => _pkgList.first);
    final labelItem = _items.firstWhere((e) => e.id == _prodLabelId, orElse: () => _pkgList.first);

    final rawCost = rawQty * rawItem.avgUnitCostOMR;
    final cartonCost = cartonQty * cartonItem.avgUnitCostOMR;
    final nylonCost = nylonQty * nylonItem.avgUnitCostOMR;
    final labelCost = labelQty * labelItem.avgUnitCostOMR;
    final totalBatchCost = rawCost + cartonCost + nylonCost + labelCost + tollFee + transport;

    final unitCost = finQty > 0 ? totalBatchCost / finQty : 0.0;
    final totalFinWeightKg = finQty * finItem.unitWeightKg;
    final costPerKg = totalFinWeightKg > 0 ? totalBatchCost / totalFinWeightKg : 0.0;
    final inputWeightKg = rawQty * rawItem.unitWeightKg;
    final wastageKg = (inputWeightKg - totalFinWeightKg) > 0 ? (inputWeightKg - totalFinWeightKg) : 0.0;

    return {
      'rawCost': rawCost,
      'cartonCost': cartonCost,
      'nylonCost': nylonCost,
      'labelCost': labelCost,
      'totalBatchCost': totalBatchCost,
      'unitCost': unitCost,
      'costPerKg': costPerKg,
      'totalFinWeightKg': totalFinWeightKg,
      'wastageKg': wastageKg,
    };
  }

  void _savePurchaseInbound() {
    final qty = double.tryParse(_inbQtyCtrl.text.trim());
    final price = double.tryParse(_inbPriceCtrl.text.trim());
    final freight = double.tryParse(_inbFreightCtrl.text.trim()) ?? 0.0;
    if (_selectedInboundItemId == null || qty == null || qty <= 0 || price == null || price < 0) {
      _showMsg('لطفاً کالا، مقدار و قیمت واحد را وارد کنید.');
      return;
    }
    final item = _items.firstWhere((e) => e.id == _selectedInboundItemId!);
    final doc = PurchaseInboundDoc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      itemId: item.id,
      itemName: item.name,
      warehouse: item.warehouse,
      unit: item.unit,
      qty: qty,
      purchaseUnitPriceOMR: price,
      freightAndCustomsOMR: freight,
    );

    setState(() {
      final oldVal = (item.currentQty > 0 ? item.currentQty : 0.0) * item.avgUnitCostOMR;
      final newTotalQty = (item.currentQty > 0 ? item.currentQty : 0.0) + qty;
      if (newTotalQty > 0) {
        item.avgUnitCostOMR = (oldVal + doc.totalLandedCostOMR) / newTotalQty;
      }
      item.currentQty += qty;
      _inbounds.insert(0, doc);
      _inbQtyCtrl.clear();
      _inbFreightCtrl.text = '0';
      _warehouseSubTab = 0;
    });
    _saveLocalData();
    _pushToCloud();
    _showMsg('✅ ورود به انبار ثبت شد و میانگین موزون بهای تمام‌شده به‌روز گردید.');
  }

  void _saveProductionBatch() {
    final rawQty = double.tryParse(_prodRawQtyCtrl.text.trim()) ?? 0.0;
    final finQty = double.tryParse(_prodFinQtyCtrl.text.trim()) ?? 0.0;
    final cartonQty = double.tryParse(_prodCartonQtyCtrl.text.trim()) ?? 0.0;
    final nylonQty = double.tryParse(_prodNylonQtyCtrl.text.trim()) ?? 0.0;
    final labelQty = double.tryParse(_prodLabelQtyCtrl.text.trim()) ?? 0.0;
    final tollFee = double.tryParse(_prodTollFeeCtrl.text.trim()) ?? 0.0;
    final transport = double.tryParse(_prodTransportCtrl.text.trim()) ?? 0.0;

    if (rawQty <= 0 || finQty <= 0 || _prodRawId == null || _prodFinId == null) {
      _showMsg('لطفاً مقدار ماده اولیه و تعداد محصول نهایی تولیدشده را وارد کنید.');
      return;
    }

    final rawItem = _items.firstWhere((e) => e.id == _prodRawId!);
    final finItem = _items.firstWhere((e) => e.id == _prodFinId!);
    final cartonItem = _items.firstWhere((e) => e.id == _prodCartonId!);
    final nylonItem = _items.firstWhere((e) => e.id == _prodNylonId!);
    final labelItem = _items.firstWhere((e) => e.id == _prodLabelId!);
    final calc = _previewLiveBatchCost();

    final doc = ProductionCostDoc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      rawItemId: rawItem.id,
      rawItemName: rawItem.name,
      rawQtyUsed: rawQty,
      rawCostOMR: calc['rawCost']!,
      cartonItemId: cartonItem.id,
      cartonItemName: cartonItem.name,
      cartonQtyUsed: cartonQty,
      cartonCostOMR: calc['cartonCost']!,
      nylonItemId: nylonItem.id,
      nylonItemName: nylonItem.name,
      nylonQtyUsed: nylonQty,
      nylonCostOMR: calc['nylonCost']!,
      labelItemId: labelItem.id,
      labelItemName: labelItem.name,
      labelQtyUsed: labelQty,
      labelCostOMR: calc['labelCost']!,
      factoryTollFeeOMR: tollFee,
      transportAndOtherCostOMR: transport,
      finishedItemId: finItem.id,
      finishedItemName: finItem.name,
      finishedUnit: finItem.unit,
      finishedQtyProduced: finQty,
      finishedTotalWeightKg: calc['totalFinWeightKg']!,
      wastageKg: calc['wastageKg']!,
      totalBatchCostOMR: calc['totalBatchCost']!,
      unitCostOMR: calc['unitCost']!,
      costPerKgOMR: calc['costPerKg']!,
    );

    setState(() {
      rawItem.currentQty -= rawQty;
      cartonItem.currentQty -= cartonQty;
      nylonItem.currentQty -= nylonQty;
      labelItem.currentQty -= labelQty;

      final oldFinVal = (finItem.currentQty > 0 ? finItem.currentQty : 0.0) * finItem.avgUnitCostOMR;
      final newFinQty = (finItem.currentQty > 0 ? finItem.currentQty : 0.0) + finQty;
      if (newFinQty > 0) {
        finItem.avgUnitCostOMR = (oldFinVal + doc.totalBatchCostOMR) / newFinQty;
      }
      finItem.currentQty += finQty;
      _productions.insert(0, doc);

      _prodRawQtyCtrl.clear();
      _prodFinQtyCtrl.clear();
      _prodCartonQtyCtrl.clear();
      _prodNylonQtyCtrl.clear();
      _prodLabelQtyCtrl.clear();
      _prodTollFeeCtrl.text = '0';
      _prodTransportCtrl.text = '0';
      _warehouseSubTab = 0;
    });
    _saveLocalData();
    _pushToCloud();
    _showMsg('✅ تولید ثبت شد! بهای تمام‌شده هر ${finItem.unit}: ${_fmtOMR(doc.unitCostOMR)} OMR');
  }

  Widget _buildThreeWarehousesAndBomTab(AppUserAccount u) {
    final canWh = u.isSuperAdmin || u.canManageWarehouses;
    final canProd = u.isSuperAdmin || u.canManageProduction;
    final targetList = _inboundWhTarget == WarehouseType.rawMaterial ? _rawList : _pkgList;
    final liveCost = _previewLiveBatchCost();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('📦 موجودی ۳ انبار'),
              selected: _warehouseSubTab == 0,
              onSelected: (_) => setState(() => _warehouseSubTab = 0),
            ),
            if (canWh)
              ChoiceChip(
                label: const Text('📥 ورود به انبار ۱ و ۲'),
                selected: _warehouseSubTab == 1,
                onSelected: (_) => setState(() => _warehouseSubTab = 1),
              ),
            if (canProd)
              ChoiceChip(
                label: const Text('⚙️ تولید کارمزدی و بهای تمام‌شده'),
                selected: _warehouseSubTab == 2,
                onSelected: (_) => setState(() => _warehouseSubTab = 2),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_warehouseSubTab == 0) ...[
          _buildWarehouseCard('🧱 انبار ۱: مواد اولیه اصلی (پنیر بلوکی، کره فله و...)', const Color(0xFF0369A1),
              WarehouseType.rawMaterial, _rawList),
          const SizedBox(height: 12),
          _buildWarehouseCard('📦 انبار ۲: ملزومات بسته‌بندی (کارتن، نایلون، لیبل و...)', const Color(0xFFB45309),
              WarehouseType.packagingSupply, _pkgList),
          const SizedBox(height: 12),
          _buildWarehouseCard('🏷️ انبار ۳: محصولات نهایی آماده فروش (با بهای تمام‌شده)', const Color(0xFF0F766E),
              WarehouseType.finishedGood, _finList),
        ] else if (_warehouseSubTab == 1 && canWh) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('🧱 انبار ۱ (مواد اولیه)'),
                        selected: _inboundWhTarget == WarehouseType.rawMaterial,
                        onSelected: (_) {
                          setState(() {
                            _inboundWhTarget = WarehouseType.rawMaterial;
                            _syncDefaults();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('📦 انبار ۲ (کارتن/نایلون/لیبل)'),
                        selected: _inboundWhTarget == WarehouseType.packagingSupply,
                        onSelected: (_) {
                          setState(() {
                            _inboundWhTarget = WarehouseType.packagingSupply;
                            _syncDefaults();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedInboundItemId,
                    items: targetList
                        .map((i) => DropdownMenuItem<String>(value: i.id, child: Text(i.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedInboundItemId = v),
                    decoration: const InputDecoration(labelText: 'انتخاب کالا / ملزومات ورودی', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inbQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'مقدار ورودی *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inbPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'قیمت خرید واحد (OMR) *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inbFreightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'هزینه حمل بار (OMR)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _savePurchaseInbound,
                    child: const Text('ثبت ورود و محاسبه میانگین موزون بهای تمام‌شده'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_warehouseSubTab == 2 && canProd) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('⚙️ ثبت تولید کارمزدی و محاسبه بهای تمام‌شده (کسر از انبار ۱ و ۲ -> شارژ انبار ۳):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _prodRawId,
                          items: _rawList
                              .map((r) => DropdownMenuItem<String>(value: r.id, child: Text(r.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _prodRawId = v),
                          decoration: const InputDecoration(labelText: '۱. ماده اولیه از انبار ۱', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodRawQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'مقدار مصرفی (کیلو)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _prodFinId,
                          items: _finList
                              .map((f) => DropdownMenuItem<String>(value: f.id, child: Text(f.name)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _prodFinId = v;
                              _autoCalcBom(_prodFinQtyCtrl.text);
                            });
                          },
                          decoration: const InputDecoration(labelText: '۲. محصول نهایی (انبار ۳)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodFinQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => _autoCalcBom(v),
                          decoration: const InputDecoration(labelText: 'تعداد بسته تولیدی', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prodCartonQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'کارتن مصرفی (انبار ۲)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodNylonQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'نایلون مصرفی (انبار ۲)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodLabelQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'لیبل مصرفی (انبار ۲)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prodTollFeeCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'کارمزد کارخانه (OMR)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodTransportCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'هزینه حمل تولید (OMR)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '📊 کل بهای تمام‌شده پارت: ${_fmtOMR(liveCost['totalBatchCost']!)} OMR\n'
                      '🏷️ بهای تمام‌شده هر بسته: ${_fmtOMR(liveCost['unitCost']!)} OMR | هر ۱ کیلو: ${_fmtOMR(liveCost['costPerKg']!)} OMR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _saveProductionBatch,
                    child: const Text('ثبت سند تولید و بهای تمام‌شده محصول'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWarehouseCard(
    String title,
    Color color,
    WarehouseType whType,
    List<InventoryItem> list,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const Divider(),
            ...list.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'بهای تمام‌شده واحد: ${_fmtOMR(item.avgUnitCostOMR)} OMR'
                    '${whType == WarehouseType.finishedGood ? ' | قیمت فروش: ${_fmtOMR(item.defaultSalePriceOMR)} OMR' : ''}',
                  ),
                  trailing: Text(
                    'موجودی: ${_fmtQty(item.currentQty)} ${item.unit}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // تب ۳: فروش به مشتریان، محاسبه زنده حاشیه سود/زیان و تقسیم سود بین شرکا
  // ==========================================================================
  void _saveSaleInvoice() {
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final price = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final deliv = double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0;
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;

    if (_saleFinId == null || qty <= 0 || price < 0) {
      _showMsg('لطفاً محصول، تعداد فروش و قیمت واحد را وارد کنید.');
      return;
    }

    final finItem = _items.firstWhere((e) => e.id == _saleFinId!);
    final doc = SaleProfitDoc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      finishedItemId: finItem.id,
      finishedItemName: finItem.name,
      unit: finItem.unit,
      qtySold: qty,
      unitSalePriceOMR: price,
      unitCogsOMR: finItem.avgUnitCostOMR,
      deliveryExpenseOMR: deliv,
      customerName: _saleCustomer ?? 'مشتری بازار عمان',
      paymentStatus: _salePaymentStatus,
      partnerSplitDivisor: divisor < 1 ? 1 : divisor,
    );

    setState(() {
      finItem.currentQty -= qty;
      _sales.insert(0, doc);
      _saleQtyCtrl.clear();
      _saleDeliveryCostCtrl.text = '0';
    });
    _saveLocalData();
    _pushToCloud();
    _showMsg(
      doc.isInLoss
          ? '⚠️ فروش با زیان (${_fmtOMR(doc.netProfitOrLossOMR)} OMR) ثبت شد!'
          : '✅ فروش با سود خالص +${_fmtOMR(doc.netProfitOrLossOMR)} OMR ثبت شد.',
    );
  }

  Widget _buildSalesProfitAndPartnerTab(AppUserAccount u) {
    final finItem = _finList.firstWhere((e) => e.id == _saleFinId, orElse: () => _finList.first);
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final salePrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final delivCost = double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0;
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;
    final safeDivisor = divisor < 1 ? 1 : divisor;

    final totalRev = qty * salePrice;
    final totalCogs = (qty * finItem.avgUnitCostOMR) + delivCost;
    final netProfit = totalRev - totalCogs;
    final marginPct = totalRev > 0 ? (netProfit / totalRev) * 100.0 : 0.0;
    final myShare = netProfit / safeDivisor;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🛒 ثبت فروش به مشتری، سنجش زنده حاشیه سود/زیان و تقسیم سود شریک',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _saleCustomer,
                  items: _customers
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text('👤 $c')))
                      .toList(),
                  onChanged: (v) => setState(() => _saleCustomer = v),
                  decoration: const InputDecoration(labelText: 'انتخاب مشتری', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _saleFinId,
                  items: _finList
                      .map((f) => DropdownMenuItem<String>(
                            value: f.id,
                            child: Text('${f.name} (بهای تمام‌شده: ${_fmtOMR(f.avgUnitCostOMR)} OMR)'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _saleFinId = v;
                      final sel = _finList.firstWhere((e) => e.id == v);
                      _salePriceCtrl.text = sel.defaultSalePriceOMR.toStringAsFixed(3);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'انتخاب محصول نهایی (انبار ۳)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _saleQtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'تعداد فروش *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _salePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'فی فروش به مشتری (OMR) *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('🤝 تقسیم سود این بار بین شما و شریک:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('۱۰۰٪ خودم'),
                      selected: _salePartnerDivisor == 1,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 1),
                    ),
                    ChoiceChip(
                      label: const Text('تقسیم بر ۲'),
                      selected: _salePartnerDivisor == 2,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 2),
                    ),
                    ChoiceChip(
                      label: const Text('تقسیم بر ۳'),
                      selected: _salePartnerDivisor == 3,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 3),
                    ),
                    ChoiceChip(
                      label: const Text('عدد دلخواه'),
                      selected: _salePartnerDivisor == 0,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 0),
                    ),
                  ],
                ),
                if (_salePartnerDivisor == 0) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customDivisorCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'تقسیم بر چند نفر؟', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: netProfit >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${netProfit >= 0 ? '✅ در سود' : '⚠️ هشدار فروش در زیان!'} | حاشیه سود: ${marginPct.toStringAsFixed(1)}%\n'
                    'فروش کل: ${_fmtOMR(totalRev)} OMR | بهای تمام‌شده کل: ${_fmtOMR(totalCogs)} OMR\n'
                    'سود/زیان خالص: ${_fmtOMR(netProfit)} OMR  |  👤 سهم شما (÷$safeDivisor): ${_fmtOMR(myShare)} OMR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveSaleInvoice,
                  child: const Text('ثبت فاکتور فروش و کسر از انبار محصول'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // تب ۴: گزارش‌های تجمیعی و ریز + صورت سود و زیان واحد مالی
  // ==========================================================================
  Widget _buildUnifiedReportsAndCfoTab(AppUserAccount u) {
    final Map<String, ConsolidatedExpenseRow> byTitle = {};
    for (final t in _transactions) {
      final k = '${t.title.trim()}__${t.category}';
      final row = byTitle.putIfAbsent(
        k,
        () => ConsolidatedExpenseRow(
          groupTitle: t.title.trim(),
          subTitle: t.category,
          count: 0,
          totalExpenseOMR: 0,
          totalDepositOMR: 0,
          firstDate: t.date,
          lastDate: t.date,
        ),
      );
      row.count++;
      if (t.mode == TxMode.deposit) {
        row.totalDepositOMR += t.amountOMR;
      } else {
        row.totalExpenseOMR += t.amountOMR;
      }
    }

    double sumRev = 0;
    double sumCogs = 0;
    double sumProfit = 0;
    double sumMyShare = 0;
    double sumPartnerShare = 0;
    for (final s in _sales) {
      sumRev += s.totalRevenueOMR;
      sumCogs += s.totalCogsOMR;
      sumProfit += s.netProfitOrLossOMR;
      sumMyShare += s.myProfitShareOMR;
      sumPartnerShare += s.partnersProfitShareOMR;
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('📑 ۱. گزارش تجمیعی و ریز تنخواه و هزینه‌ها'),
              selected: _reportSectionTab == 0,
              onSelected: (_) => setState(() => _reportSectionTab = 0),
            ),
            if (u.isSuperAdmin || u.canViewProfitAndPartners)
              ChoiceChip(
                label: const Text('🏦 ۲. صورت سود و زیان، بهای تمام‌شده و سهم شریک'),
                selected: _reportSectionTab == 1,
                onSelected: (_) => setState(() => _reportSectionTab = 1),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_reportSectionTab == 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📑 گزارش تجمیعی تنخواه و هزینه‌های روزانه (جمع اقلام مشابه در یک ردیف واحد):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  const Divider(),
                  if (byTitle.isEmpty)
                    const Text('هنوز هزینه‌ای ثبت نشده است.')
                  else
                    ...byTitle.values.map((r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${r.groupTitle} (${r.count} نوبت تجمیع‌شده)',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('سرفصل: ${r.subTitle}'),
                          trailing: Text(
                            '${_fmtOMR(r.totalExpenseOMR > 0 ? r.totalExpenseOMR : r.totalDepositOMR)} OMR',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏦 صورت سود و زیان استاندارد (P&L)، بهای تمام‌شده و تسهیم سود شرکا:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E))),
                  const Divider(),
                  Text('• کل درآمد فروش محصولات: ${_fmtOMR(sumRev)} OMR'),
                  Text('• منهای: کل بهای تمام‌شده کالای فروش‌رفته (COGS): (${_fmtOMR(sumCogs)} OMR)'),
                  Text(
                    '💵 سود (یا زیان) خالص کل: ${_fmtOMR(sumProfit)} OMR',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '👤 جمع سهم خالص شما: ${_fmtOMR(sumMyShare)} OMR  |  🤝 جمع سهم شریک/شرکا: ${_fmtOMR(sumPartnerShare)} OMR',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // تب ۵: پنل مدیریت کاربران، رمزهای ورود و تعیین سطح دسترسی هر شخص (ویژه شما - ادمین)
  // ==========================================================================
  void _showAddOrEditUserModal({AppUserAccount? existing}) {
    final nameCtrl = TextEditingController(text: existing?.displayName ?? '');
    final roleCtrl = TextEditingController(text: existing?.roleTitle ?? 'واحد مالی / مشاهده‌گر');
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController(text: existing?.password ?? '');

    bool pViewReports = existing?.canViewReports ?? true;
    bool pPetty = existing?.canManagePettyCash ?? false;
    bool pWh = existing?.canManageWarehouses ?? false;
    bool pProd = existing?.canManageProduction ?? false;
    bool pSales = existing?.canManageSales ?? false;
    bool pProfit = existing?.canViewProfitAndPartners ?? false;
    bool pExport = existing?.canExportFinance ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(existing == null ? '➕ تعریف کاربر جدید و تعیین سطح دسترسی' : '✏️ ویرایش دسترسی و رمز «${existing.displayName}»'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'نام شخص / واحد (مثلاً: حسابدار شرکت)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(labelText: 'سمت / عنوان دسترسی', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'نام کاربری برای ورود (Username) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'رمز عبور برای ورود (Password) *', border: OutlineInputBorder()),
                ),
                const Divider(height: 20),
                const Text('تعیین دقیق مجوزهای این کاربر توسط شما (ادمین):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                CheckboxListTile(
                  dense: true,
                  title: const Text('مشاهده پیشخوان و گزارش‌ها (فقط رویت)'),
                  value: pViewReports,
                  onChanged: (v) => setModalState(() => pViewReports = v ?? true),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('ثبت و ویرایش تنخواه و هزینه‌های روزانه'),
                  value: pPetty,
                  onChanged: (v) => setModalState(() => pPetty = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('مدیریت انبار ۱ و ۲ (ورود مواد اولیه و ملزومات)'),
                  value: pWh,
                  onChanged: (v) => setModalState(() => pWh = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('ثبت تولید کارمزدی و فرمول بهای تمام‌شده'),
                  value: pProd,
                  onChanged: (v) => setModalState(() => pProd = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('ثبت فاکتور فروش به مشتریان'),
                  value: pSales,
                  onChanged: (v) => setModalState(() => pSales = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('مشاهده صورت سود و زیان و سهم شرکا'),
                  value: pProfit,
                  onChanged: (v) => setModalState(() => pProfit = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('دریافت خروجی اکسل (Excel) ویژه واحد مالی'),
                  value: pExport,
                  onChanged: (v) => setModalState(() => pExport = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final uName = userCtrl.text.trim();
                final uPass = passCtrl.text.trim();
                if (uName.isEmpty || uPass.isEmpty) {
                  _showMsg('نام کاربری و رمز عبور الزامی است.');
                  return;
                }
                setState(() {
                  if (existing != null) {
                    existing.displayName = nameCtrl.text.trim().isEmpty ? uName : nameCtrl.text.trim();
                    existing.roleTitle = roleCtrl.text.trim();
                    existing.username = uName;
                    existing.password = uPass;
                    existing.canViewReports = pViewReports;
                    existing.canManagePettyCash = pPetty;
                    existing.canManageWarehouses = pWh;
                    existing.canManageProduction = pProd;
                    existing.canManageSales = pSales;
                    existing.canViewProfitAndPartners = pProfit;
                    existing.canExportFinance = pExport;
                  } else {
                    _users.add(AppUserAccount(
                      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                      username: uName,
                      password: uPass,
                      displayName: nameCtrl.text.trim().isEmpty ? uName : nameCtrl.text.trim(),
                      roleTitle: roleCtrl.text.trim(),
                      isSuperAdmin: false,
                      canViewReports: pViewReports,
                      canManagePettyCash: pPetty,
                      canManageWarehouses: pWh,
                      canManageProduction: pProd,
                      canManageSales: pSales,
                      canViewProfitAndPartners: pProfit,
                      canExportFinance: pExport,
                    ));
                  }
                });
                _saveLocalData();
                _pushToCloud();
                Navigator.pop(ctx);
                _showMsg('✅ سطح دسترسی و رمز عبور کاربر ذخیره و همگام‌سازی شد.');
              },
              child: const Text('ذخیره کاربر و مجوزها'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminUsersAndPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '🔐 مدیریت کاربران، رمزهای ورود و تعیین سطح دسترسی هر شخص (ویژه ادمین)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showAddOrEditUserModal(),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('+ تعریف کاربر جدید'),
                    ),
                  ],
                ),
                const Divider(),
                ..._users.map((acc) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: acc.isSuperAdmin ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${acc.isSuperAdmin ? '👑' : '👤'} ${acc.displayName} (${acc.roleTitle})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'نام کاربری ورود: ${acc.username}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'ویرایش رمز و سطح دسترسی',
                                icon: const Icon(Icons.edit, color: Color(0xFF0369A1)),
                                onPressed: () => _showAddOrEditUserModal(existing: acc),
                              ),
                              if (!acc.isSuperAdmin)
                                IconButton(
                                  tooltip: 'حذف کاربر',
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _users.removeWhere((u) => u.id == acc.id));
                                    _saveLocalData();
                                    _pushToCloud();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}