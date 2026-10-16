// ============================================================================
// سامانه جامع مدیریت هوشمند افق عمان (Oman Smart ERP - Enterprise Multi-Language & Multi-Currency Edition)
// فایل اصلی: oman_erp_master.dart
// معماری لایه‌ای کامل شامل تمام امکانات قبلی + ۶ الزام جدید سازمانی:
// ۱. واحد پول قابل انتخاب در کل سیستم («ریال» و «دلار USD») با ضریب تبدیل قابل تنظیم توسط مدیر
// ۲. صدور خودکار «برگه خروج کالا از انبار (Warehouse Exit Slip)» به محض ثبت سفارش/فاکتور مشتری با قابلیت چاپ رسمی و ذخیره
// ۳. رابط کاربری چندزبانه کامل (فارسی FA، انگلیسی EN، عربی AR) با تغییر خودکار جهت صفحه (RTL / LTR)
// ۴. دروازه ورود دو مرحله‌ای: دریافت آدرس دیتابیس سرور در اولین اجرا پیش از ورود کاربران + بخش دائمی تنظیمات آدرس دیتابیس در تنظیمات
// ۵. سیستم پشتیبان‌گیری خودکار زمان‌بندی‌شده (Scheduled Auto-Backup) و بک‌آپ/بازیابی دستی (Manual Backup & Restore)
// ۶. ۶ استاندارد حسابرسی مدیر مالی (قفل موجودی منفی ۳ انبار، P&L دوطبقه، تسویه نسیه مشتریان و کارمزد کارخانه، مرجوعی/ضایعات، VAT 5%، لاگ حسابرسی) + گزارش‌ساز پویا، اکسل و چاپ
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const OmanSmartErpApp());
}

typedef MyApp = OmanSmartErpApp;

enum AppLang { fa, en, ar }

enum AppCurrency { rial, usd }

class OmanSmartErpApp extends StatelessWidget {
  const OmanSmartErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oman Smart ERP | سامانه هوشمند افق عمان',
      theme: ThemeData(
        primaryColor: const Color(0xFF0F766E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
      ),
      home: const ErpRootGate(),
    );
  }
}

// ============================================================================
// ۱. مدل کاربر و سطوح دسترسی (Table: users)
// ============================================================================
class AppUserAccount {
  final String id;
  String username;
  String password;
  String displayName;
  String roleTitle;
  bool isSuperAdmin;

  bool canViewReports;
  bool canManagePettyCash;
  bool canManageWarehouses;
  bool canManageProduction;
  bool canManageSales;
  bool canViewProfitAndPartners;
  bool canExportFinance;

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
// ۲. مدل لاگ حسابرسی (Table: audit_logs)
// ============================================================================
class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String username;
  final String section;
  final String description;
  final double amountOMR;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.username,
    required this.section,
    required this.description,
    required this.amountOMR,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'username': username,
        'section': section,
        'description': description,
        'amountOMR': amountOMR,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> j) => AuditLogEntry(
        id: j['id']?.toString() ?? '',
        timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
        username: j['username']?.toString() ?? 'System',
        section: j['section']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        amountOMR: (j['amountOMR'] as num?)?.toDouble() ?? 0.0,
      );
}

// ============================================================================
// ۳. مدل «برگه خروج کالا از انبار» (Table: warehouse_exit_slips)
// صادرشده به صورت خودکار به ازای هر سفارش/فاکتور مشتری
// ============================================================================
class WarehouseExitSlip {
  final String slipNumber;
  final String orderInvoiceId;
  final DateTime issueDate;
  final String customerName;
  final String customerAddressOrPhone;
  final String itemId;
  final String itemName;
  final String warehouseName;
  final double qty;
  final String unit;
  final double totalWeightKg;
  final double unitPriceBase;
  final double totalAmountBase;
  String driverOrReceiverName;
  String vehiclePlate;
  String deliveryStatus;
  String note;
  final String issuedBy;

  WarehouseExitSlip({
    required this.slipNumber,
    required this.orderInvoiceId,
    required this.issueDate,
    required this.customerName,
    this.customerAddressOrPhone = '',
    required this.itemId,
    required this.itemName,
    this.warehouseName = 'انبار ۳: محصولات نهایی آماده فروش',
    required this.qty,
    required this.unit,
    required this.totalWeightKg,
    required this.unitPriceBase,
    required this.totalAmountBase,
    this.driverOrReceiverName = '',
    this.vehiclePlate = '',
    this.deliveryStatus = 'صادر شده - آماده خروج از انبار',
    this.note = '',
    this.issuedBy = 'مدیر',
  });

  Map<String, dynamic> toJson() => {
        'slipNumber': slipNumber,
        'orderInvoiceId': orderInvoiceId,
        'issueDate': issueDate.toIso8601String(),
        'customerName': customerName,
        'customerAddressOrPhone': customerAddressOrPhone,
        'itemId': itemId,
        'itemName': itemName,
        'warehouseName': warehouseName,
        'qty': qty,
        'unit': unit,
        'totalWeightKg': totalWeightKg,
        'unitPriceBase': unitPriceBase,
        'totalAmountBase': totalAmountBase,
        'driverOrReceiverName': driverOrReceiverName,
        'vehiclePlate': vehiclePlate,
        'deliveryStatus': deliveryStatus,
        'note': note,
        'issuedBy': issuedBy,
      };

  factory WarehouseExitSlip.fromJson(Map<String, dynamic> j) => WarehouseExitSlip(
        slipNumber: j['slipNumber']?.toString() ?? 'EXIT-000',
        orderInvoiceId: j['orderInvoiceId']?.toString() ?? '',
        issueDate: DateTime.tryParse(j['issueDate']?.toString() ?? '') ?? DateTime.now(),
        customerName: j['customerName']?.toString() ?? '',
        customerAddressOrPhone: j['customerAddressOrPhone']?.toString() ?? '',
        itemId: j['itemId']?.toString() ?? '',
        itemName: j['itemName']?.toString() ?? '',
        warehouseName: j['warehouseName']?.toString() ?? 'انبار ۳: محصولات نهایی',
        qty: (j['qty'] as num?)?.toDouble() ?? 0.0,
        unit: j['unit']?.toString() ?? 'بسته',
        totalWeightKg: (j['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
        unitPriceBase: (j['unitPriceBase'] as num?)?.toDouble() ?? 0.0,
        totalAmountBase: (j['totalAmountBase'] as num?)?.toDouble() ?? 0.0,
        driverOrReceiverName: j['driverOrReceiverName']?.toString() ?? '',
        vehiclePlate: j['vehiclePlate']?.toString() ?? '',
        deliveryStatus: j['deliveryStatus']?.toString() ?? 'صادر شده - آماده خروج از انبار',
        note: j['note']?.toString() ?? '',
        issuedBy: j['issuedBy']?.toString() ?? 'مدیر',
      );
}

// ============================================================================
// ۴. مدل نسخه پشتیبان دیتابیس (Table: backup_snapshots)
// ============================================================================
class BackupSnapshotRecord {
  final String id;
  final DateTime createdAt;
  final String triggerType;
  final String createdBy;
  final int totalRecordsCount;
  final String summaryText;
  final String jsonPayload;

  BackupSnapshotRecord({
    required this.id,
    required this.createdAt,
    required this.triggerType,
    required this.createdBy,
    required this.totalRecordsCount,
    required this.summaryText,
    required this.jsonPayload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'triggerType': triggerType,
        'createdBy': createdBy,
        'totalRecordsCount': totalRecordsCount,
        'summaryText': summaryText,
        'jsonPayload': jsonPayload,
      };

  factory BackupSnapshotRecord.fromJson(Map<String, dynamic> j) => BackupSnapshotRecord(
        id: j['id']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        triggerType: j['triggerType']?.toString() ?? 'manual',
        createdBy: j['createdBy']?.toString() ?? 'System',
        totalRecordsCount: (j['totalRecordsCount'] as num?)?.toInt() ?? 0,
        summaryText: j['summaryText']?.toString() ?? '',
        jsonPayload: j['jsonPayload']?.toString() ?? '{}',
      );
}

// ============================================================================
// ۵. مدل‌های تنخواه، ۳ انبار، تولید، فروش و گزارش‌ساز پویا
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
  final bool hasVat5Percent;
  final DateTime date;
  final String topic;
  final String category;
  final String title;
  final String note;
  final String createdBy;
  final Map<String, String> customValues;

  TransactionRecord({
    required this.id,
    required this.mode,
    required this.source,
    required this.amountOMR,
    this.hasVat5Percent = false,
    required this.date,
    required this.topic,
    required this.category,
    required this.title,
    this.note = '',
    this.createdBy = 'مدیر',
    this.customValues = const {},
  });

  double get vatAmountOMR => hasVat5Percent ? amountOMR * (5.0 / 105.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'source': source.name,
        'amountOMR': amountOMR,
        'hasVat5Percent': hasVat5Percent,
        'date': date.toIso8601String(),
        'topic': topic,
        'category': category,
        'title': title,
        'note': note,
        'createdBy': createdBy,
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
        hasVat5Percent: j['hasVat5Percent'] == true,
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        topic: j['topic']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        createdBy: j['createdBy']?.toString() ?? 'مدیر',
        customValues: (j['customValues'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}

enum WarehouseType {
  rawMaterial,
  packagingSupply,
  finishedGood,
}

class InventoryItem {
  final String id;
  String name;
  final WarehouseType warehouse;
  String unit;
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
  final String createdBy;
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
    this.createdBy = 'مدیر',
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
        'createdBy': createdBy,
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
        createdBy: j['createdBy']?.toString() ?? 'مدیر',
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
  bool isFactoryFeePaid;
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
  final String createdBy;

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
    this.isFactoryFeePaid = false,
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
    this.createdBy = 'مدیر',
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
        'isFactoryFeePaid': isFactoryFeePaid,
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
        'createdBy': createdBy,
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
        isFactoryFeePaid: j['isFactoryFeePaid'] == true,
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
        createdBy: j['createdBy']?.toString() ?? 'مدیر',
      );
}

class SaleProfitDoc {
  final String id;
  final String exitSlipNumber;
  final DateTime date;
  final String finishedItemId;
  final String finishedItemName;
  final String unit;
  final double qtySold;
  final double unitSalePriceOMR;
  final double unitCogsOMR;
  final double deliveryExpenseOMR;
  final bool hasVat5Percent;
  final String customerName;
  String paymentStatus;
  double paidAmountOMR;
  final int partnerSplitDivisor;
  final bool isReturnDoc;
  final String createdBy;

  SaleProfitDoc({
    required this.id,
    this.exitSlipNumber = '',
    required this.date,
    required this.finishedItemId,
    required this.finishedItemName,
    required this.unit,
    required this.qtySold,
    required this.unitSalePriceOMR,
    required this.unitCogsOMR,
    required this.deliveryExpenseOMR,
    this.hasVat5Percent = false,
    required this.customerName,
    required this.paymentStatus,
    required this.paidAmountOMR,
    required this.partnerSplitDivisor,
    this.isReturnDoc = false,
    this.createdBy = 'مدیر',
  });

  double get sign => isReturnDoc ? -1.0 : 1.0;
  double get totalRevenueOMR => sign * (qtySold * unitSalePriceOMR);
  double get vatAmountOMR => hasVat5Percent ? totalRevenueOMR * 0.05 : 0.0;
  double get totalInvoiceWithVatOMR => totalRevenueOMR + vatAmountOMR;
  double get remainingReceivableOMR =>
      isReturnDoc ? 0.0 : ((totalInvoiceWithVatOMR - paidAmountOMR) > 0 ? (totalInvoiceWithVatOMR - paidAmountOMR) : 0.0);

  double get totalCogsOMR => (sign * qtySold * unitCogsOMR) + deliveryExpenseOMR;
  double get netProfitOrLossOMR => totalRevenueOMR - totalCogsOMR;
  double get profitMarginPercent =>
      totalRevenueOMR.abs() > 0 ? (netProfitOrLossOMR / totalRevenueOMR.abs()) * 100.0 : 0.0;
  bool get isInLoss => !isReturnDoc && netProfitOrLossOMR < -0.0005;

  double get myProfitShareOMR =>
      partnerSplitDivisor > 1 ? netProfitOrLossOMR / partnerSplitDivisor : netProfitOrLossOMR;
  double get partnersProfitShareOMR => netProfitOrLossOMR - myProfitShareOMR;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exitSlipNumber': exitSlipNumber,
        'date': date.toIso8601String(),
        'finishedItemId': finishedItemId,
        'finishedItemName': finishedItemName,
        'unit': unit,
        'qtySold': qtySold,
        'unitSalePriceOMR': unitSalePriceOMR,
        'unitCogsOMR': unitCogsOMR,
        'deliveryExpenseOMR': deliveryExpenseOMR,
        'hasVat5Percent': hasVat5Percent,
        'customerName': customerName,
        'paymentStatus': paymentStatus,
        'paidAmountOMR': paidAmountOMR,
        'partnerSplitDivisor': partnerSplitDivisor,
        'isReturnDoc': isReturnDoc,
        'createdBy': createdBy,
      };

  factory SaleProfitDoc.fromJson(Map<String, dynamic> j) => SaleProfitDoc(
        id: j['id']?.toString() ?? '',
        exitSlipNumber: j['exitSlipNumber']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        finishedItemId: j['finishedItemId']?.toString() ?? '',
        finishedItemName: j['finishedItemName']?.toString() ?? '',
        unit: j['unit']?.toString() ?? 'بسته',
        qtySold: (j['qtySold'] as num?)?.toDouble() ?? 0.0,
        unitSalePriceOMR: (j['unitSalePriceOMR'] as num?)?.toDouble() ?? 0.0,
        unitCogsOMR: (j['unitCogsOMR'] as num?)?.toDouble() ?? 0.0,
        deliveryExpenseOMR: (j['deliveryExpenseOMR'] as num?)?.toDouble() ?? 0.0,
        hasVat5Percent: j['hasVat5Percent'] == true,
        customerName: j['customerName']?.toString() ?? '',
        paymentStatus: j['paymentStatus']?.toString() ?? 'نقدی / واریز بانکی',
        paidAmountOMR: (j['paidAmountOMR'] as num?)?.toDouble() ?? 0.0,
        partnerSplitDivisor: (j['partnerSplitDivisor'] as num?)?.toInt() ?? 1,
        isReturnDoc: j['isReturnDoc'] == true,
        createdBy: j['createdBy']?.toString() ?? 'مدیر',
      );
}

class CustomReportRow {
  final DateTime date;
  final String docId;
  final String docType;
  final String titleOrItem;
  final String partyOrTopic;
  final String categoryOrWh;
  final double qty;
  final String unit;
  final double unitPriceOrCostOMR;
  final double totalAmountOMR;
  final double cogsOMR;
  final double profitOMR;
  final String statusOrUser;

  CustomReportRow({
    required this.date,
    required this.docId,
    required this.docType,
    required this.titleOrItem,
    required this.partyOrTopic,
    required this.categoryOrWh,
    required this.qty,
    required this.unit,
    required this.unitPriceOrCostOMR,
    required this.totalAmountOMR,
    required this.cogsOMR,
    required this.profitOMR,
    required this.statusOrUser,
  });
}

// ============================================================================
// ویجت اصلی با دروازه دو مرحله‌ای (۱. تنظیم آدرس دیتابیس در اولین اجرا -> ۲. ورود کاربران)
// + موتور چندزبانه (FA / EN / AR) + موتور چندارزی (ریال / دلار با ضریب تبدیل) + بک‌آپ خودکار/دستی
// ============================================================================
class ErpRootGate extends StatefulWidget {
  const ErpRootGate({super.key});

  @override
  State<ErpRootGate> createState() => _ErpRootGateState();
}

class _ErpRootGateState extends State<ErpRootGate> {
  // ۱. تنظیمات چندزبانه (Multi-language: فارسی، انگلیسی، عربی)
  AppLang _lang = AppLang.fa;

  String _t(String fa, String en, String ar) {
    switch (_lang) {
      case AppLang.fa:
        return fa;
      case AppLang.en:
        return en;
      case AppLang.ar:
        return ar;
    }
  }

  TextDirection get _activeDirection =>
      _lang == AppLang.en ? TextDirection.ltr : TextDirection.rtl;

  // ۲. تنظیمات واحد پول قابل انتخاب (ریال / دلار) و ضریب تبدیل (نرخ ارز) قابل تنظیم توسط مدیر
  AppCurrency _currency = AppCurrency.rial;
  double _usdExchangeRate = 2.60;

  String get _currUnit => _currency == AppCurrency.rial
      ? _t('ریال (OMR)', 'Rial (OMR)', 'ريال (OMR)')
      : _t('دلار (USD \$)', 'USD (\$)', 'دولار (USD \$)');

  double _toDisplayAmount(double baseRialAmount) {
    if (_currency == AppCurrency.rial) return baseRialAmount;
    return baseRialAmount * (_usdExchangeRate > 0 ? _usdExchangeRate : 1.0);
  }

  double _fromInputToBaseRial(double enteredAmount) {
    if (_currency == AppCurrency.rial) return enteredAmount;
    return _usdExchangeRate > 0 ? (enteredAmount / _usdExchangeRate) : enteredAmount;
  }

  String _fmtOMR(double baseRialAmount) {
    final converted = _toDisplayAmount(baseRialAmount);
    return _currency == AppCurrency.rial
        ? converted.toStringAsFixed(3)
        : converted.toStringAsFixed(2);
  }

  String _fmtMoneyWithUnit(double baseRialAmount) => '${_fmtOMR(baseRialAmount)} $_currUnit';

  // ۳. وضعیت تنظیم اولیه آدرس دیتابیس سرور در اولین اجرای نرم‌افزار (First-Run DB Setup)
  bool _isDbAddressConfigured = false;
  String _cloudSyncUrl = '';
  String _dbApiKey = '';
  bool _autoSyncOnEveryChange = true;
  bool _isSyncing = false;
  String _lastSyncStatus = 'آماده اتصال به دیتابیس سرور';

  final TextEditingController _initialDbUrlCtrl = TextEditingController();
  final TextEditingController _initialDbKeyCtrl = TextEditingController();

  // ۴. سیستم پشتیبان‌گیری خودکار زمان‌بندی‌شده و دستی (Automated & Manual Backup System)
  bool _autoBackupEnabled = true;
  int _autoBackupIntervalMinutes = 60;
  Timer? _autoBackupTimer;
  List<BackupSnapshotRecord> _backups = [];

  // ۵. کاربران، لاگ حسابرسی و برگه‌های خروج از انبار
  AppUserAccount? _currentUser;
  List<AppUserAccount> _users = [];
  List<AuditLogEntry> _auditLogs = [];
  List<WarehouseExitSlip> _exitSlips = [];

  final TextEditingController _loginUserCtrl = TextEditingController();
  final TextEditingController _loginPassCtrl = TextEditingController();
  final TextEditingController _setupAdminNameCtrl = TextEditingController(text: 'مدیر ارشد (ادمین)');
  final TextEditingController _setupAdminUserCtrl = TextEditingController(text: 'admin');
  final TextEditingController _setupAdminPassCtrl = TextEditingController();
  final TextEditingController _loginCloudUrlCtrl = TextEditingController();

  int _selectedIndex = 0;

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
      options: ['نقدی (Cash)', 'کارت بانکی', 'حواله / موبایل بانک'],
    ),
    CustomFilterDef(
      id: 'cf_receipt',
      name: 'وضعیت فاکتور',
      options: ['دارای فاکتور رسمی', 'رسید عادی', 'بدون رسید'],
    ),
  ];

  List<TransactionRecord> _transactions = [];

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

  TxMode _formMode = TxMode.expense;
  ExpenseSource _formSource = ExpenseSource.petty;
  bool _txHasVat = false;
  final TextEditingController _txAmountCtrl = TextEditingController();
  final TextEditingController _txTitleCtrl = TextEditingController();
  final TextEditingController _txNoteCtrl = TextEditingController();
  DateTime _txDate = DateTime.now();
  late String _selectedTopic;
  late String _selectedCategory;
  final Map<String, String> _selectedCustomValues = {};

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
  bool _prodTollPaid = false;
  final TextEditingController _prodTransportCtrl = TextEditingController(text: '0');

  String? _adjustItemId;
  final TextEditingController _adjustQtyDeltaCtrl = TextEditingController();
  final TextEditingController _adjustReasonCtrl = TextEditingController();

  bool _isSaleReturnMode = false;
  bool _saleHasVat = false;
  String? _saleFinId;
  String? _saleCustomer;
  final TextEditingController _saleQtyCtrl = TextEditingController();
  final TextEditingController _salePriceCtrl = TextEditingController();
  final TextEditingController _saleDeliveryCostCtrl = TextEditingController(text: '0');
  final TextEditingController _saleDriverNameCtrl = TextEditingController();
  final TextEditingController _saleVehiclePlateCtrl = TextEditingController();
  final TextEditingController _saleCustomerAddressCtrl = TextEditingController();
  String _salePaymentStatus = 'نقدی / واریز بانکی';
  int _salePartnerDivisor = 1;
  final TextEditingController _customDivisorCtrl = TextEditingController(text: '2');

  int _reportMainMode = 0;
  final TextEditingController _customRepTitleCtrl = TextEditingController(text: 'گزارش جامع مالی، انبار و سفارشات');
  final TextEditingController _repFromDateCtrl = TextEditingController();
  final TextEditingController _repToDateCtrl = TextEditingController();
  DateTime? _repFromDate;
  DateTime? _repToDate;

  bool _incExpensesInRep = true;
  bool _incInboundsInRep = true;
  bool _incProductionsInRep = true;
  bool _incSalesInRep = true;
  String _customGroupBy = 'by_item';

  bool _colDate = true;
  bool _colType = true;
  bool _colTitle = true;
  bool _colParty = true;
  bool _colCategory = true;
  bool _colQty = true;
  bool _colUnitPrice = true;
  bool _colTotalAmount = true;
  bool _colCogsAndProfit = true;
  bool _colUserAndStatus = true;

  bool _deductOpexBeforePartnerSplit = true;
  int _globalPartnerSplitDivisor = 2;

  int _adminSubTab = 0;

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
    _loadLocalData().then((_) {
      _restartAutoBackupTimer();
    });
  }

  @override
  void dispose() {
    _autoBackupTimer?.cancel();
    super.dispose();
  }

  void _restartAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    if (!_autoBackupEnabled || _autoBackupIntervalMinutes <= 0) return;
    _autoBackupTimer = Timer.periodic(
      Duration(minutes: _autoBackupIntervalMinutes),
      (_) {
        _createBackupSnapshot(
          triggerType: 'auto_scheduled',
          customNote: 'بک‌آپ خودکار زمان‌بندی‌شده (هر $_autoBackupIntervalMinutes دقیقه)',
          silent: true,
        );
      },
    );
  }

  void _syncDefaults() {
    for (final cf in _customFilters) {
      if (!_selectedCustomValues.containsKey(cf.id) && cf.options.isNotEmpty) {
        _selectedCustomValues[cf.id] = cf.options.first;
      }
    }
    if (_customers.isNotEmpty) _saleCustomer ??= _customers.first;
    if (_items.isNotEmpty) _adjustItemId ??= _items.first.id;
    final targetList = _inboundWhTarget == WarehouseType.rawMaterial ? _rawList : _pkgList;
    if (targetList.isNotEmpty) {
      if (_selectedInboundItemId == null || !targetList.any((e) => e.id == _selectedInboundItemId)) {
        _selectedInboundItemId = targetList.first.id;
        _inbPriceCtrl.text = _fmtOMR(targetList.first.avgUnitCostOMR);
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
        _salePriceCtrl.text = _fmtOMR(_finList.first.defaultSalePriceOMR);
      }
    }
  }

  void _addAuditLog(String section, String desc, double amount) {
    _auditLogs.insert(
      0,
      AuditLogEntry(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        username: _currentUser?.displayName ?? 'System',
        section: section,
        description: desc,
        amountOMR: amount,
      ),
    );
  }

  File _getLocalDbFile() {
    final dir = Directory.systemTemp;
    return File('${dir.path}/oman_smart_erp_v6_enterprise.json');
  }

  Future<void> _loadLocalData() async {
    try {
      final f = _getLocalDbFile();
      if (await f.exists()) {
        final content = await f.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          _applyJsonState(Map<String, dynamic>.from(decoded), includeBackups: true);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalData() async {
    try {
      final f = _getLocalDbFile();
      await f.writeAsString(jsonEncode(_exportStateJson(includeBackups: true)));
    } catch (_) {}
  }

  Map<String, dynamic> _exportStateJson({bool includeBackups = false}) {
    final map = <String, dynamic>{
      'schemaVersion': '6.0-enterprise',
      'updatedAt': DateTime.now().toIso8601String(),
      'lang': _lang.name,
      'currency': _currency.name,
      'usdExchangeRate': _usdExchangeRate,
      'isDbAddressConfigured': _isDbAddressConfigured,
      'cloudSyncUrl': _cloudSyncUrl,
      'dbApiKey': _dbApiKey,
      'autoSyncOnEveryChange': _autoSyncOnEveryChange,
      'autoBackupEnabled': _autoBackupEnabled,
      'autoBackupIntervalMinutes': _autoBackupIntervalMinutes,
      'users': _users.map((u) => u.toJson()).toList(),
      'auditLogs': _auditLogs.map((a) => a.toJson()).toList(),
      'exitSlips': _exitSlips.map((s) => s.toJson()).toList(),
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
    if (includeBackups) {
      map['backups'] = _backups.map((b) => b.toJson()).toList();
    }
    return map;
  }

  void _applyJsonState(Map<String, dynamic> data, {bool includeBackups = false}) {
    setState(() {
      if (data['lang'] != null) {
        _lang = AppLang.values.firstWhere(
          (l) => l.name == data['lang'].toString(),
          orElse: () => AppLang.fa,
        );
      }
      if (data['currency'] != null) {
        _currency = AppCurrency.values.firstWhere(
          (c) => c.name == data['currency'].toString(),
          orElse: () => AppCurrency.rial,
        );
      }
      if (data['usdExchangeRate'] is num) {
        final rate = (data['usdExchangeRate'] as num).toDouble();
        if (rate > 0) _usdExchangeRate = rate;
      }
      if (data['isDbAddressConfigured'] == true) {
        _isDbAddressConfigured = true;
      }
      if (data['cloudSyncUrl'] != null && data['cloudSyncUrl'].toString().isNotEmpty) {
        _cloudSyncUrl = data['cloudSyncUrl'].toString();
        _loginCloudUrlCtrl.text = _cloudSyncUrl;
        _initialDbUrlCtrl.text = _cloudSyncUrl;
      }
      if (data['dbApiKey'] != null) {
        _dbApiKey = data['dbApiKey'].toString();
        _initialDbKeyCtrl.text = _dbApiKey;
      }
      if (data['autoSyncOnEveryChange'] is bool) {
        _autoSyncOnEveryChange = data['autoSyncOnEveryChange'] as bool;
      }
      if (data['autoBackupEnabled'] is bool) {
        _autoBackupEnabled = data['autoBackupEnabled'] as bool;
      }
      if (data['autoBackupIntervalMinutes'] is num) {
        _autoBackupIntervalMinutes = (data['autoBackupIntervalMinutes'] as num).toInt();
      }
      if (data['users'] is List) {
        final uList = (data['users'] as List)
            .map((e) => AppUserAccount.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (uList.isNotEmpty) _users = uList;
      }
      if (data['auditLogs'] is List) {
        _auditLogs = (data['auditLogs'] as List)
            .map((e) => AuditLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      if (data['exitSlips'] is List) {
        _exitSlips = (data['exitSlips'] as List)
            .map((e) => WarehouseExitSlip.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
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
      if (includeBackups && data['backups'] is List) {
        _backups = (data['backups'] as List)
            .map((e) => BackupSnapshotRecord.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      _syncDefaults();
    });
  }

  Future<void> _pushToCloud() async {
    if (_cloudSyncUrl.trim().isEmpty || _cloudSyncUrl.startsWith('local://')) return;
    setState(() {
      _isSyncing = true;
      _lastSyncStatus = _t('در حال آپلود اطلاعات به دیتابیس سرور...', 'Uploading to server DB...', 'جاري رفع البيانات إلى الخادم...');
    });
    try {
      final uri = Uri.parse(_cloudSyncUrl.trim());
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.putUrl(uri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (_dbApiKey.trim().isNotEmpty) {
        req.headers.set('Authorization', 'Bearer ${_dbApiKey.trim()}');
      }
      req.add(utf8.encode(jsonEncode(_exportStateJson(includeBackups: false))));
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() => _lastSyncStatus = _t('✅ همگام‌سازی موفق با دیتابیس سرور', '✅ Synced with Server DB', '✅ تمت المزامنة مع قاعدة البيانات'));
      }
      client.close();
    } catch (_) {
      setState(() => _lastSyncStatus = _t('ذخیره در دیتابیس محلی دستگاه', 'Saved to local device DB', 'تم الحفظ محلياً'));
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<bool> _pullFromCloud({String? overrideUrl}) async {
    final targetUrl = (overrideUrl ?? _cloudSyncUrl).trim().isNotEmpty
        ? (overrideUrl ?? _cloudSyncUrl).trim()
        : _loginCloudUrlCtrl.text.trim();
    if (targetUrl.isEmpty) {
      _showMsg(_t('لطفاً ابتدا آدرس دیتابیس سرور را وارد کنید.', 'Please enter the Database Server URL first.', 'يرجى إدخال عنوان قاعدة البيانات أولاً.'));
      return false;
    }
    _cloudSyncUrl = targetUrl;
    _loginCloudUrlCtrl.text = targetUrl;
    _initialDbUrlCtrl.text = targetUrl;

    if (targetUrl.startsWith('local://')) {
      setState(() {
        _isDbAddressConfigured = true;
        _lastSyncStatus = _t('متصل به دیتابیس محلی دستگاه', 'Connected to Local DB', 'متصل بقاعدة البيانات المحلية');
      });
      await _saveLocalData();
      return true;
    }

    setState(() {
      _isSyncing = true;
      _lastSyncStatus = _t('در حال دریافت کاربران و اطلاعات از دیتابیس سرور...', 'Fetching users & data from Server DB...', 'جاري جلب المستخدمين والبيانات من الخادم...');
    });
    try {
      final uri = Uri.parse(targetUrl);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(uri);
      if (_dbApiKey.trim().isNotEmpty) {
        req.headers.set('Authorization', 'Bearer ${_dbApiKey.trim()}');
      }
      final resp = await req.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = await resp.transform(utf8.decoder).join();
        if (body.isNotEmpty && body != 'null') {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            _applyJsonState(Map<String, dynamic>.from(decoded));
          }
        }
        setState(() {
          _isDbAddressConfigured = true;
          _lastSyncStatus = _t('✅ اطلاعات و کاربران از سرور دریافت شد', '✅ Users & data synced from server', '✅ تم جلب البيانات والمستخدمين من الخادم');
        });
        await _saveLocalData();
        _showMsg(_t('✅ اتصال به دیتابیس برقرار شد و اطلاعات کاربران بارگذاری گردید.', '✅ Connected to database and loaded user accounts.', '✅ تم الاتصال بقاعدة البيانات وتحميل حسابات المستخدمين.'));
        client.close();
        return true;
      }
      client.close();
    } catch (_) {
      _showMsg(_t('⚠️ سرور در دسترس نیست؛ آدرس دیتابیس ذخیره شد و حالت هیبرید فعال گردید.', '⚠️ Server unreachable; DB URL saved in hybrid mode.', '⚠️ تعذر الوصول للخادم؛ تم حفظ العنوان في الوضع الهجين.'));
    } finally {
      setState(() => _isSyncing = false);
    }
    setState(() => _isDbAddressConfigured = true);
    await _saveLocalData();
    return true;
  }

  Future<void> _createBackupSnapshot({
    required String triggerType,
    String customNote = '',
    bool silent = false,
  }) async {
    final payloadMap = _exportStateJson(includeBackups: false);
    final payloadStr = jsonEncode(payloadMap);
    final totalRecs = _transactions.length +
        _inbounds.length +
        _productions.length +
        _sales.length +
        _exitSlips.length +
        _items.length;

    final snap = BackupSnapshotRecord(
      id: 'BKP-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      triggerType: triggerType,
      createdBy: _currentUser?.displayName ?? 'System Scheduler',
      totalRecordsCount: totalRecs,
      summaryText: customNote.isNotEmpty
          ? customNote
          : 'فروش: ${_sales.length} | برگه خروج: ${_exitSlips.length} | تولید: ${_productions.length} | تنخواه: ${_transactions.length}',
      jsonPayload: payloadStr,
    );

    setState(() {
      _backups.insert(0, snap);
      if (_backups.length > 30) {
        _backups = _backups.sublist(0, 30);
      }
    });

    try {
      final fileName = 'Oman_ERP_Backup_${_fmtDate(snap.createdAt)}_${snap.id}.json';
      final f = File('${Directory.systemTemp.path}/$fileName');
      await f.writeAsString(payloadStr, encoding: utf8);
    } catch (_) {}

    await _saveLocalData();
    if (!silent) {
      _addAuditLog('پشتیبان‌گیری (Backup)', 'ایجاد نسخه پشتیبان (${snap.id}) — $totalRecs رکورد', 0);
      _showMsg(_t('✅ نسخه پشتیبان دیتابیس با موفقیت ایجاد و ذخیره شد.', '✅ Database backup snapshot created and saved.', '✅ تم إنشاء وحفظ نسخة احتياطية لقاعدة البيانات بنجاح.'));
    }
  }

  Future<void> _restoreFromSnapshot(BackupSnapshotRecord snap) async {
    await _createBackupSnapshot(
      triggerType: 'pre_restore',
      customNote: 'نسخه ایمنی خودکار پیش از بازیابی ${snap.id}',
      silent: true,
    );
    try {
      final decoded = jsonDecode(snap.jsonPayload);
      if (decoded is Map) {
        _applyJsonState(Map<String, dynamic>.from(decoded), includeBackups: false);
        _addAuditLog('بازیابی دیتابیس (Restore)', 'بازیابی اطلاعات به نسخه پشتیبان ${snap.id}', 0);
        await _saveLocalData();
        if (_autoSyncOnEveryChange) {
          await _pushToCloud();
        }
        _showMsg(_t('✅ بازیابی دیتابیس (Restore) با موفقیت انجام شد.', '✅ Database restored successfully.', '✅ تمت استعادة قاعدة البيانات بنجاح.'));
      }
    } catch (_) {
      _showMsg(_t('❌ خطا در ساختار فایل پشتیبان!', '❌ Invalid backup payload!', '❌ خطأ في ملف النسخة الاحتياطية!'));
    }
  }

  Future<void> _exportBackupToFileOrClipboard(BackupSnapshotRecord snap) async {
    final fileName = 'Oman_ERP_Backup_${_fmtDate(snap.createdAt)}.json';
    try {
      final f = File('${Directory.current.path}/$fileName');
      await f.writeAsString(snap.jsonPayload, encoding: utf8);
      Clipboard.setData(ClipboardData(text: snap.jsonPayload));
      _showMsg(_t('✅ فایل پشتیبان ($fileName) در پوشه برنامه ذخیره و در حافظه کپی شد.', '✅ Backup saved to $fileName & copied to clipboard.', '✅ تم حفظ النسخة الاحتياطية في $fileName ونسخها للحافظة.'));
    } catch (_) {
      Clipboard.setData(ClipboardData(text: snap.jsonPayload));
      _showMsg(_t('✅ متن کامل فایل پشتیبان (JSON) در کلیپ‌بورد کپی شد.', '✅ Backup JSON copied to clipboard.', '✅ تم نسخ بيانات النسخة الاحتياطية إلى الحافظة.'));
    }
  }

  WarehouseExitSlip _issueWarehouseExitSlip(SaleProfitDoc saleDoc, InventoryItem finItem) {
    final seq = 1001 + _exitSlips.length;
    final slipNo = 'EXIT-$seq';
    final totalWeight = saleDoc.qtySold * finItem.unitWeightKg;

    final slip = WarehouseExitSlip(
      slipNumber: slipNo,
      orderInvoiceId: saleDoc.id,
      issueDate: saleDoc.date,
      customerName: saleDoc.customerName,
      customerAddressOrPhone: _saleCustomerAddressCtrl.text.trim().isEmpty
          ? 'مسقط، سلطنت عمان'
          : _saleCustomerAddressCtrl.text.trim(),
      itemId: finItem.id,
      itemName: finItem.name,
      warehouseName: 'انبار ۳: محصولات نهایی آماده فروش',
      qty: saleDoc.qtySold,
      unit: finItem.unit,
      totalWeightKg: totalWeight,
      unitPriceBase: saleDoc.unitSalePriceOMR,
      totalAmountBase: saleDoc.totalInvoiceWithVatOMR,
      driverOrReceiverName: _saleDriverNameCtrl.text.trim().isEmpty
          ? 'تحویل مستقیم / باربری شرکت'
          : _saleDriverNameCtrl.text.trim(),
      vehiclePlate: _saleVehiclePlateCtrl.text.trim(),
      deliveryStatus: saleDoc.isReturnDoc
          ? 'برگشت به انبار (مرجوعی)'
          : 'صادر شده - آماده خروج از انبار',
      note: 'صادرشده خودکار بابت سفارش مشتری (${saleDoc.paymentStatus})',
      issuedBy: saleDoc.createdBy,
    );

    _exitSlips.insert(0, slip);
    return slip;
  }

  Future<void> _printOrSaveWarehouseExitSlip(WarehouseExitSlip slip) async {
    final dirStr = _lang == AppLang.en ? 'ltr' : 'rtl';
    final alignStr = _lang == AppLang.en ? 'left' : 'right';

    final htmlDoc = '''<!DOCTYPE html>
<html lang="${_lang.name}" dir="$dirStr">
<head>
<meta charset="UTF-8">
<title>${_t('برگه خروج کالا از انبار', 'Warehouse Exit Slip', 'سند إخراج بضاعة من المستودع')} - ${slip.slipNumber}</title>
<style>
  body { font-family: Tahoma, Arial, sans-serif; margin: 24px; color: #0f172a; }
  .box { border: 2px solid #0f766e; border-radius: 10px; padding: 20px; }
  .header { border-bottom: 2px solid #0f766e; padding-bottom: 12px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }
  h1 { font-size: 20px; color: #0f766e; margin: 0; }
  .meta-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; background: #f8fafc; padding: 12px; border-radius: 8px; border: 1px solid #cbd5e1; margin-bottom: 16px; font-size: 13px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 10px; }
  th, td { border: 1px solid #94a3b8; padding: 9px 10px; text-align: $alignStr; }
  th { background: #e2e8f0; font-weight: bold; }
  .signs { margin-top: 44px; display: flex; justify-content: space-around; text-align: center; font-size: 12.5px; }
  @media print { .no-print { display: none; } }
</style>
</head>
<body onload="window.print()">
  <div class="no-print" style="margin-bottom:14px;">
    <button onclick="window.print()" style="padding:8px 18px; background:#0f766e; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold;">
      🖨️ ${_t('چاپ برگه خروج از انبار / ذخیره PDF', 'Print Warehouse Exit Slip / Save PDF', 'طباعة سند إخراج البضاعة / حفظ PDF')}
    </button>
  </div>
  <div class="box">
    <div class="header">
      <div>
        <h1>📦 ${_t('برگه رسمی خروج کالا از انبار (حواله تحویل سفارش مشتری)', 'Official Warehouse Exit & Delivery Slip', 'سند رسمي لإخراج البضاعة من المستودع')}</h1>
        <div style="font-size:12px; color:#475569; margin-top:4px;">Oman Smart ERP — ${_t('سامانه هوشمند افق عمان', 'Oman Horizon Smart ERP', 'نظام أفق عمان الذكي')}</div>
      </div>
      <div style="text-align:$alignStr; font-size:13px;">
        <b>${_t('شماره برگه خروج:', 'Exit Slip No:', 'رقم سند الإخراج:')} ${slip.slipNumber}</b><br>
        ${_t('کد فاکتور مرجع:', 'Order Invoice ID:', 'رقم الفاتورة المرجعي:')} #${slip.orderInvoiceId.substring(saleIdSlice(slip.orderInvoiceId))}<br>
        ${_t('تاریخ صدور:', 'Issue Date:', 'تاريخ الإصدار:')} ${_fmtDate(slip.issueDate)}
      </div>
    </div>
    <div class="meta-grid">
      <div><b>👤 ${_t('نام مشتری / تحویل‌گیرنده:', 'Customer Name:', 'اسم العميل / المستلم:')}</b> ${slip.customerName}</div>
      <div><b>📍 ${_t('آدرس / تلفن مشتری:', 'Address / Phone:', 'عنوان / هاتف العميل:')}</b> ${slip.customerAddressOrPhone}</div>
      <div><b>🏭 ${_t('انبار مبدا خروج:', 'Source Warehouse:', 'المستودع المصدر:')}</b> ${slip.warehouseName}</div>
      <div><b>🚚 ${_t('راننده / پلاک خودرو:', 'Driver / Vehicle:', 'السائق / رقم المركبة:')}</b> ${slip.driverOrReceiverName} ${slip.vehiclePlate.isNotEmpty ? "(${slip.vehiclePlate})" : ""}</div>
      <div><b>📌 ${_t('وضعیت خروج:', 'Delivery Status:', 'حالة التسليم:')}</b> ${slip.deliveryStatus}</div>
      <div><b>👨‍💼 ${_t('صادرکننده برگه:', 'Issued By:', 'صادر بواسطة:')}</b> ${slip.issuedBy}</div>
    </div>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>${_t('کد کالا', 'Item Code', 'كود الصنف')}</th>
          <th>${_t('شرح کالا / اقلام سفارش', 'Item Description', 'وصف الصنف')}</th>
          <th>${_t('تعداد / مقدار', 'Quantity', 'الكمية')}</th>
          <th>${_t('واحد', 'Unit', 'الوحدة')}</th>
          <th>${_t('وزن کل (Kg)', 'Total Weight (Kg)', 'الوزن الإجمالي (كجم)')}</th>
          <th>${_t('فی واحد', 'Unit Price', 'سعر الوحدة')} ($_currUnit)</th>
          <th>${_t('مبلغ کل سفارش', 'Total Amount', 'المبلغ الإجمالي')} ($_currUnit)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>1</td>
          <td>${slip.itemId}</td>
          <td><b>${slip.itemName}</b></td>
          <td><b>${_fmtQty(slip.qty)}</b></td>
          <td>${slip.unit}</td>
          <td>${_fmtQty(slip.totalWeightKg)} Kg</td>
          <td>${_fmtOMR(slip.unitPriceBase)}</td>
          <td><b>${_fmtOMR(slip.totalAmountBase)}</b></td>
        </tr>
      </tbody>
    </table>
    <div style="margin-top:14px; font-size:12px; color:#334155;">
      <b>${_t('توضیحات:', 'Notes:', 'ملاحظات:')}</b> ${slip.note}
    </div>
    <div class="signs">
      <div>${_t('مهر و امضای انباردار (تحویل‌دهنده)', 'Warehouse Keeper Signature', 'توقيع أمين المستودع')}<br><br>___________________</div>
      <div>${_t('امضای راننده / مامور حمل', 'Driver / Carrier Signature', 'توقيع السائق / الناقل')}<br><br>___________________</div>
      <div>${_t('امضای مدیر فروش / مالی', 'Sales / Finance Approval', 'توقيع مدير المبيعات / المالية')}<br><br>___________________</div>
      <div>${_t('مهر و امضای مشتری (تحویل‌گیرنده قطعی)', 'Customer Receiver Signature', 'توقيع العميل المستلم')}<br><br>___________________</div>
    </div>
  </div>
</body>
</html>''';

    final fileName = 'Exit_Slip_${slip.slipNumber}.html';
    try {
      final f = File('${Directory.current.path}/$fileName');
      await f.writeAsString(htmlDoc, encoding: utf8);
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', f.path]);
      }
      _showMsg(_t('✅ برگه خروج (${slip.slipNumber}) در فایل $fileName ذخیره شد و آماده چاپ است.', '✅ Exit Slip (${slip.slipNumber}) saved to $fileName & opened for printing.', '✅ تم حفظ سند الإخراج (${slip.slipNumber}) وهو جاهز للطباعة.'));
    } catch (_) {
      Clipboard.setData(ClipboardData(
        text: 'برگه خروج از انبار: ${slip.slipNumber}\n'
            'تاریخ: ${_fmtDate(slip.issueDate)}\n'
            'مشتری: ${slip.customerName} (${slip.customerAddressOrPhone})\n'
            'کالا: ${slip.itemName} — تعداد: ${_fmtQty(slip.qty)} ${slip.unit} (${_fmtQty(slip.totalWeightKg)} Kg)\n'
            'مبلغ کل: ${_fmtMoneyWithUnit(slip.totalAmountBase)}\n'
            'راننده: ${slip.driverOrReceiverName} | وضعیت: ${slip.deliveryStatus}',
      ));
      _showMsg(_t('✅ مشخصات کامل برگه خروج (${slip.slipNumber}) جهت چاپ یا ارسال کپی شد.', '✅ Exit slip (${slip.slipNumber}) copied to clipboard.', '✅ تم نسخ تفاصيل سند الإخراج (${slip.slipNumber}) للحافظة.'));
    }
  }

  int saleIdSlice(String id) => id.length > 6 ? id.length - 6 : 0;

  void _showExitSlipPreviewDialog(WarehouseExitSlip slip) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _activeDirection,
        child: AlertDialog(
          title: Text('📦 ${_t('برگه خروج کالا از انبار', 'Warehouse Exit Slip', 'سند إخراج بضاعة من المستودع')} (${slip.slipNumber})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0F766E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔢 ${_t('شماره برگه خروج:', 'Slip Number:', 'رقم السند:')} ${slip.slipNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('📅 ${_t('تاریخ صدور:', 'Issue Date:', 'تاريخ الإصدار:')} ${_fmtDate(slip.issueDate)}'),
                      Text('👤 ${_t('نام مشتری:', 'Customer:', 'العميل:')} ${slip.customerName}'),
                      Text('📍 ${_t('آدرس/تلفن:', 'Address/Phone:', 'العنوان/الهاتف:')} ${slip.customerAddressOrPhone}'),
                      const Divider(),
                      Text('🏷️ ${_t('اقلام سفارش:', 'Order Item:', 'الصنف المطلوب:')} ${slip.itemName}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('📦 ${_t('تعداد خروجی از انبار ۳:', 'Quantity:', 'الكمية:')} ${_fmtQty(slip.qty)} ${slip.unit} (${_fmtQty(slip.totalWeightKg)} Kg)'),
                      Text('💰 ${_t('ارزش کل سفارش:', 'Total Order Value:', 'إجمالي قيمة الطلب:')} ${_fmtMoneyWithUnit(slip.totalAmountBase)}'),
                      const Divider(),
                      Text('🚚 ${_t('راننده / تحویل‌گیرنده:', 'Driver / Receiver:', 'السائق / المستلم:')} ${slip.driverOrReceiverName}'),
                      Text('📌 ${_t('وضعیت:', 'Status:', 'الحالة:')} ${slip.deliveryStatus}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('بستن', 'Close', 'إغلاق')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _printOrSaveWarehouseExitSlip(slip);
              },
              icon: const Icon(Icons.print, size: 18),
              label: Text(_t('چاپ رسمی / ذخیره برگه خروج', 'Print / Save Exit Slip', 'طباعة / حفظ سند الإخراج')),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyAndExchangeRateDialog() {
    final canEditRate = _currentUser == null || _currentUser!.isSuperAdmin;
    final rateCtrl = TextEditingController(text: _usdExchangeRate.toStringAsFixed(3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
          textDirection: _activeDirection,
          child: AlertDialog(
            title: Text(_t(
              '💱 انتخاب واحد پول سیستم و تنظیم ضریب تبدیل دلار',
              '💱 Currency Selection & USD Exchange Rate',
              '💱 اختيار العملة وضبط سعر صرف الدولار',
            )),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t(
                      'واحد پول فعال جهت نمایش در کل سیستم (قیمت‌ها، فاکتورها، انبارها و گزارش‌ها):',
                      'Active display currency across the entire ERP system:',
                      'العملة النشطة للعرض في جميع أنحاء النظام:',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(_t('🇴🇲 ریال (OMR / Rial)', '🇴🇲 Rial (OMR)', '🇴🇲 ريال (OMR)')),
                        selected: _currency == AppCurrency.rial,
                        onSelected: (_) {
                          setModalState(() => _currency = AppCurrency.rial);
                          setState(() => _currency = AppCurrency.rial);
                        },
                      ),
                      ChoiceChip(
                        label: Text(_t('🇺🇸 دلار آمریکا (USD \$)', '🇺🇸 US Dollar (USD \$)', '🇺🇸 دولار أمريكي (USD \$)')),
                        selected: _currency == AppCurrency.usd,
                        onSelected: (_) {
                          setModalState(() => _currency = AppCurrency.usd);
                          setState(() => _currency = AppCurrency.usd);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: rateCtrl,
                    enabled: canEditRate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _t(
                        'ضریب تبدیل ریال به دلار (۱ ریال = چند دلار؟) *',
                        'Exchange Rate Multiplier (1 Rial = ? USD) *',
                        'معامل تحويل الريال إلى الدولار (1 ريال = كم دولار؟) *',
                      ),
                      helperText: _t(
                        'فقط مدیر کل (ادمین) مجاز به تغییر ضریب تبدیل ارز است.',
                        'Only Super Admin can modify the exchange rate multiplier.',
                        'المدير العام فقط يمكنه تعديل سعر الصرف.',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_t('انصراف', 'Cancel', 'إلغاء')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final parsed = double.tryParse(rateCtrl.text.trim());
                  if (canEditRate && parsed != null && parsed > 0) {
                    setState(() {
                      _usdExchangeRate = parsed;
                    });
                    _addAuditLog('تنظیمات ارز', 'تغییر واحد پول به ${_currency.name.toUpperCase()} با ضریب $_usdExchangeRate', 0);
                  }
                  _saveLocalData();
                  if (_autoSyncOnEveryChange) _pushToCloud();
                  Navigator.pop(ctx);
                  _showMsg(_t(
                    '✅ واحد پول ($_currUnit) و ضریب تبدیل ($_usdExchangeRate) در کل سیستم اعمال شد.',
                    '✅ Currency ($_currUnit) & rate ($_usdExchangeRate) applied across system.',
                    '✅ تم تطبيق العملة ($_currUnit) وسعر الصرف ($_usdExchangeRate) في كل النظام.',
                  ));
                },
                child: Text(_t('ذخیره و اعمال در کل سیستم', 'Save & Apply System-Wide', 'حفظ وتطبيق في كل النظام')),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
  double get _totalWorkOpexOMR => _transactions
      .where((t) => t.mode == TxMode.expense && (t.source == ExpenseSource.petty || t.source == ExpenseSource.pocket))
      .fold(0.0, (s, t) => s + t.amountOMR);
  double get _pettyBalance => _totalPettyIn - _totalPettyOut;

  double get _totalSalesRevenueOMR => _sales.fold(0.0, (s, r) => s + r.totalRevenueOMR);
  double get _totalGrossProfitOMR => _sales.fold(0.0, (s, r) => s + r.netProfitOrLossOMR);
  double get _totalUnpaidReceivablesOMR => _sales.fold(0.0, (s, r) => s + r.remainingReceivableOMR);
  double get _totalUnpaidFactoryTollOMR => _productions
      .where((p) => !p.isFactoryFeePaid)
      .fold(0.0, (s, p) => s + p.factoryTollFeeOMR);

  Widget _buildTopLangAndCurrencyBar() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('🇮🇷 فارسی'),
          selected: _lang == AppLang.fa,
          onSelected: (_) {
            setState(() => _lang = AppLang.fa);
            _saveLocalData();
          },
        ),
        ChoiceChip(
          label: const Text('🇬🇧 English'),
          selected: _lang == AppLang.en,
          onSelected: (_) {
            setState(() => _lang = AppLang.en);
            _saveLocalData();
          },
        ),
        ChoiceChip(
          label: const Text('🇴🇲 العربية'),
          selected: _lang == AppLang.ar,
          onSelected: (_) {
            setState(() => _lang = AppLang.ar);
            _saveLocalData();
          },
        ),
        ActionChip(
          label: Text('💱 $_currUnit'),
          onPressed: _showCurrencyAndExchangeRateDialog,
        ),
      ],
    );
  }

  Widget _buildLoginOrSetupGate() {
    final isFirstSetup = _users.isEmpty;

    return Directionality(
      textDirection: _activeDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopLangAndCurrencyBar(),
                      const SizedBox(height: 12),
                      const Icon(Icons.verified_user, size: 50, color: Color(0xFF0F766E)),
                      const SizedBox(height: 8),
                      Text(
                        _t(
                          'سامانه هوشمند افق عمان (Oman Smart ERP)',
                          'Oman Horizon Smart ERP System',
                          'نظام أفق عمان الذكي لإدارة الموارد (ERP)',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 4),

                      if (!_isDbAddressConfigured) ...[
                        Text(
                          _t(
                            'گام ۱ (اجرای اولیه): تنظیم آدرس دیتابیس سرور مرکزی پیش از ورود',
                            'Step 1 (First Run): Configure Central Database Server URL Before Login',
                            'الخطوة ١ (التشغيل الأول): إعداد عنوان قاعدة البيانات المركزية قبل الدخول',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Text(
                          _t(
                            'لطفاً آدرس دیتابیس / سرور وب‌سایت را وارد کنید تا لیست کاربران، رمزهای عبور تعیین‌شده توسط مدیر و اطلاعات پایه از سرور بارگذاری شود:',
                            'Please enter the Database / Server Endpoint URL so user accounts, admin-defined passwords, and initial data are synced:',
                            'يرجى إدخال رابط قاعدة البيانات / الخادم لتحميل حسابات المستخدمين وكلمات المرور والبيانات الأساسية:',
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _initialDbUrlCtrl,
                          decoration: InputDecoration(
                            labelText: _t('آدرس دیتابیس سرور (Database URL) *', 'Database Server URL *', 'عنوان خادم قاعدة البيانات *'),
                            hintText: 'https://your-server.com/api/oman_erp.json',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _initialDbKeyCtrl,
                          decoration: InputDecoration(
                            labelText: _t('کلید امنیتی / توکن دیتابیس (اختیاری)', 'Database API Token / Key (Optional)', 'مفتاح الأمان لقاعدة البيانات (اختياري)'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isSyncing
                              ? null
                              : () async {
                                  final url = _initialDbUrlCtrl.text.trim();
                                  if (url.isEmpty) {
                                    _showMsg(_t(
                                      'لطفاً آدرس دیتابیس سرور را وارد کنید (یا برای دیتابیس محلی گزینه زیر را بزنید).',
                                      'Please enter the Database Server URL.',
                                      'يرجى إدخال عنوان قاعدة البيانات.',
                                    ));
                                    return;
                                  }
                                  _dbApiKey = _initialDbKeyCtrl.text.trim();
                                  await _pullFromCloud(overrideUrl: url);
                                },
                          icon: const Icon(Icons.cloud_download),
                          label: Text(_t(
                            'ثبت آدرس دیتابیس، دریافت کاربران از سرور و ادامه به ورود',
                            'Save DB URL, Sync Users & Proceed to Login',
                            'حفظ عنوان قاعدة البيانات ومزامنة المستخدمين والمتابعة للدخول',
                          )),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _cloudSyncUrl = 'local://oman_erp_master_db';
                              _initialDbUrlCtrl.text = _cloudSyncUrl;
                              _isDbAddressConfigured = true;
                            });
                            _saveLocalData();
                          },
                          child: Text(_t(
                            'راه‌اندازی اولیه روی دیتابیس داخلی دستگاه (ویژه سیستم مادر ادمین)',
                            'Initialize Local Master Database (Admin Mother System)',
                            'تهيئة قاعدة البيانات المحلية (النظام الرئيسي للمدير)',
                          )),
                        ),
                      ] else ...[
                        Text(
                          isFirstSetup
                              ? _t('راه‌اندازی اولیه حساب «ادمین اصلی (مدیر کل)»', 'Initial Super Admin Account Setup', 'الإعداد الأولي لحساب المدير العام')
                              : _t('ورود کاربران با نام کاربری و رمز عبور تعیین‌شده توسط مدیر', 'User Login (Admin-Assigned Credentials)', 'تسجيل دخول المستخدمين'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCCFBF1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '🔗 DB: ${_cloudSyncUrl.isEmpty ? "Local" : _cloudSyncUrl}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _isDbAddressConfigured = false),
                                child: Text(_t('تغییر آدرس دیتابیس', 'Change DB URL', 'تغيير عنوان قاعدة البيانات'),
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 22),
                        if (isFirstSetup) ...[
                          TextField(
                            controller: _setupAdminNameCtrl,
                            decoration: InputDecoration(
                              labelText: _t('عنوان شما در برنامه', 'Admin Display Name', 'اسم المدير'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _setupAdminUserCtrl,
                            decoration: InputDecoration(
                              labelText: _t('نام کاربری ادمین (مثلاً admin) *', 'Admin Username *', 'اسم مستخدم المدير *'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _setupAdminPassCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _t('رمز عبور ادمین (حداقل ۴ کاراکتر) *', 'Admin Password (min 4 chars) *', 'كلمة مرور المدير *'),
                              border: const OutlineInputBorder(),
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
                                _showMsg(_t(
                                  'لطفاً نام کاربری و رمز عبور (حداقل ۴ کاراکتر) وارد کنید.',
                                  'Please enter username and password (min 4 chars).',
                                  'يرجى إدخال اسم المستخدم وكلمة المرور (4 أحرف على الأقل).',
                                ));
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
                                _users = [adminAcc, financeViewer];
                                _currentUser = adminAcc;
                                _selectedIndex = 0;
                              });
                              _addAuditLog('امنیت', 'راه‌اندازی اولیه حساب ادمین اصلی و دیتابیس', 0);
                              _createBackupSnapshot(
                                triggerType: 'auto_scheduled',
                                customNote: 'نسخه پشتیبان اولیه بدو راه‌اندازی سیستم',
                                silent: true,
                              );
                              _saveLocalData();
                              _pushToCloud();
                            },
                            icon: const Icon(Icons.lock_open),
                            label: Text(_t('ثبت رمز ادمین و ورود به سامانه', 'Create Admin & Login', 'إنشاء حساب المدير والدخول')),
                          ),
                        ] else ...[
                          TextField(
                            controller: _loginUserCtrl,
                            decoration: InputDecoration(
                              labelText: _t('نام کاربری (Username) *', 'Username *', 'اسم المستخدم *'),
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _loginPassCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _t('رمز عبور (Password) *', 'Password *', 'كلمة المرور *'),
                              prefixIcon: const Icon(Icons.key),
                              border: const OutlineInputBorder(),
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
                                _showMsg(_t(
                                  '❌ نام کاربری یا رمز عبور اشتباه است.',
                                  '❌ Invalid username or password.',
                                  '❌ اسم المستخدم أو كلمة المرور غير صحيحة.',
                                ));
                                return;
                              }
                              setState(() {
                                _currentUser = matched.first;
                                _selectedIndex = 0;
                                _loginPassCtrl.clear();
                              });
                              _addAuditLog('ورود به سیستم', 'ورود کاربر ${matched.first.displayName} به سامانه', 0);
                              _saveLocalData();
                            },
                            icon: const Icon(Icons.login),
                            label: Text(_t('ورود به سامانه', 'Login to ERP', 'تسجيل الدخول للنظام')),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isSyncing ? null : () => _pullFromCloud(),
                            icon: const Icon(Icons.cloud_download, size: 18),
                            label: Text(_t(
                              'به‌روزرسانی لیست کاربران و اطلاعات از سرور دیتابیس',
                              'Sync Latest Users & Data from Database Server',
                              'تحديث قائمة المستخدمين والبيانات من الخادم',
                            )),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return _buildLoginOrSetupGate();
    }

    final u = _currentUser!;
    final pages = <Widget>[];
    final navItems = <BottomNavigationBarItem>[];

    pages.add(_buildPettyCashAndExpensesTab(u));
    navItems.add(BottomNavigationBarItem(
      icon: const Icon(Icons.account_balance_wallet),
      label: _t('تنخواه و هزینه', 'Petty Cash', 'العهدة والمصاريف'),
    ));

    pages.add(_buildThreeWarehousesAndBomTab(u));
    navItems.add(BottomNavigationBarItem(
      icon: const Icon(Icons.warehouse),
      label: _t('۳ انبار و خروج کالا', '3 Warehouses', 'المستودعات والإخراج'),
    ));

    if (u.isSuperAdmin || u.canManageSales) {
      pages.add(_buildSalesProfitAndPartnerTab(u));
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.point_of_sale),
        label: _t('سفارش، فروش و حواله', 'Orders & Sales', 'الطلبات والمبيعات'),
      ));
    }

    if (u.isSuperAdmin || u.canViewReports) {
      pages.add(_buildCustomReportBuilderAndCfoTab(u));
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.assessment),
        label: _t('گزارش‌ساز و مالی', 'Reports & P&L', 'التقارير والمالية'),
      ));
    }

    if (u.isSuperAdmin) {
      pages.add(_buildAdminUsersAndPermissionsTab());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.admin_panel_settings),
        label: _t('تنظیمات، دیتابیس و بک‌آپ', 'Admin, DB & Backup', 'الإدارة وقاعدة البيانات'),
      ));
    }

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Directionality(
      textDirection: _activeDirection,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: u.isSuperAdmin ? const Color(0xFF0F766E) : const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${u.isSuperAdmin ? '👑' : '👤'} ${u.displayName} — ${u.roleTitle}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              Text(
                '$_lastSyncStatus | 💱 $_currUnit ${_currency == AppCurrency.usd ? "(Rate: $_usdExchangeRate)" : ""}',
                style: const TextStyle(fontSize: 10.5, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _showCurrencyAndExchangeRateDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currency == AppCurrency.rial ? '🇴🇲 ریال/OMR' : '🇺🇸 USD \$',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ),
            PopupMenuButton<AppLang>(
              tooltip: _t('تغییر زبان برنامه', 'Change Language', 'تغيير اللغة'),
              icon: const Icon(Icons.language),
              onSelected: (newLang) {
                setState(() => _lang = newLang);
                _saveLocalData();
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: AppLang.fa, child: Text('🇮🇷 فارسی (Persian)')),
                PopupMenuItem(value: AppLang.en, child: Text('🇬🇧 English (LTR)')),
                PopupMenuItem(value: AppLang.ar, child: Text('🇴🇲 العربية (Arabic)')),
              ],
            ),
            IconButton(
              tooltip: _t('دریافت اطلاعات از دیتابیس سرور', 'Pull from DB Server', 'جلب من خادم قاعدة البيانات'),
              onPressed: _isSyncing ? null : () => _pullFromCloud(),
              icon: const Icon(Icons.cloud_download),
            ),
            if (u.isSuperAdmin || u.canManagePettyCash || u.canManageWarehouses || u.canManageSales)
              IconButton(
                tooltip: _t('آپلود اطلاعات به دیتابیس سرور', 'Push to DB Server', 'رفع إلى خادم قاعدة البيانات'),
                onPressed: _isSyncing ? null : _pushToCloud,
                icon: const Icon(Icons.cloud_upload),
              ),
            IconButton(
              tooltip: _t('خروج از حساب', 'Logout', 'تسجيل الخروج'),
              onPressed: () => setState(() => _currentUser = null),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
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
                    _pettyBalance >= 0
                        ? _t('مانده تنخواه', 'Petty Balance', 'رصيد العهدة')
                        : _t('طلب تنخواه', 'Petty Deficit', 'عجز العهدة'),
                    _fmtMoneyWithUnit(_pettyBalance.abs()),
                  ),
                  _buildHeaderMetric(
                    _t('طلب از مشتریان', 'Receivables', 'ذمم العملاء'),
                    _fmtMoneyWithUnit(_totalUnpaidReceivablesOMR),
                  ),
                  _buildHeaderMetric(
                    _t('بدهی به کارخانه', 'Factory Payable', 'مستحقات المصنع'),
                    _fmtMoneyWithUnit(_totalUnpaidFactoryTollOMR),
                  ),
                  _buildHeaderMetric(
                    _t('برگه‌های خروج', 'Exit Slips', 'سندات الإخراج'),
                    '${_exitSlips.length}',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
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
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showAddNewProductOrItemDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'بسته ۱ کیلویی');
    final weightCtrl = TextEditingController(text: '1.0');
    final costCtrl = TextEditingController(text: '0');
    final saleCtrl = TextEditingController(text: '0');
    final cartonCtrl = TextEditingController(text: '0.1');
    final nylonCtrl = TextEditingController(text: '1');
    final labelCtrl = TextEditingController(text: '1');
    WarehouseType wh = WarehouseType.finishedGood;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
          textDirection: _activeDirection,
          child: AlertDialog(
            title: Text(_t('➕ تعریف محصول یا کالای جدید در انبارها', '➕ Add New Inventory Item / Product', '➕ إضافة منتج أو صنف جديد للمستودعات')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<WarehouseType>(
                    value: wh,
                    items: [
                      DropdownMenuItem(value: WarehouseType.rawMaterial, child: Text(_t('🧱 انبار ۱: ماده اولیه اصلی', 'Warehouse 1: Raw Material', 'مستودع ١: مواد خام'))),
                      DropdownMenuItem(value: WarehouseType.packagingSupply, child: Text(_t('📦 انبار ۲: ملزومات بسته‌بندی', 'Warehouse 2: Packaging Supply', 'مستودع ٢: مستلزمات تغليف'))),
                      DropdownMenuItem(value: WarehouseType.finishedGood, child: Text(_t('🏷️ انبار ۳: محصول نهایی آماده فروش', 'Warehouse 3: Finished Good', 'مستودع ٣: منتج نهائي'))),
                    ],
                    onChanged: (v) => setModalState(() => wh = v!),
                    decoration: InputDecoration(labelText: _t('انتخاب انبار', 'Target Warehouse', 'اختر المستودع'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: _t('نام کالا / محصول جدید *', 'Item / Product Name *', 'اسم الصنف / المنتج *'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: InputDecoration(labelText: _t('واحد شمارش', 'Unit', 'الوحدة'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: _t('وزن واحد (Kg)', 'Unit Weight (Kg)', 'وزن الوحدة (كجم)'), border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: '${_t('بهای تمام‌شده اولیه', 'Initial Cost', 'التكلفة الأولية')} ($_currUnit)', border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: saleCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: '${_t('قیمت فروش پیش‌فرض', 'Default Sale Price', 'سعر البيع الافتراضي')} ($_currUnit)', border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  if (wh == WarehouseType.finishedGood) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: cartonCtrl, decoration: InputDecoration(labelText: _t('ضریب کارتن', 'Carton/Unit', 'كرتون/وحدة'), border: const OutlineInputBorder()))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: nylonCtrl, decoration: InputDecoration(labelText: _t('ضریب نایلون', 'Nylon/Unit', 'نايلون/وحدة'), border: const OutlineInputBorder()))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: labelCtrl, decoration: InputDecoration(labelText: _t('ضریب لیبل', 'Label/Unit', 'ملصق/وحدة'), border: const OutlineInputBorder()))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
              ElevatedButton(
                onPressed: () {
                  final nm = nameCtrl.text.trim();
                  if (nm.isEmpty) return;
                  final newItem = InventoryItem(
                    id: 'itm_${DateTime.now().millisecondsSinceEpoch}',
                    name: nm,
                    warehouse: wh,
                    unit: unitCtrl.text.trim().isEmpty ? 'عدد' : unitCtrl.text.trim(),
                    unitWeightKg: double.tryParse(weightCtrl.text.trim()) ?? 1.0,
                    avgUnitCostOMR: _fromInputToBaseRial(double.tryParse(costCtrl.text.trim()) ?? 0.0),
                    defaultSalePriceOMR: _fromInputToBaseRial(double.tryParse(saleCtrl.text.trim()) ?? 0.0),
                    defaultCartonPerUnit: double.tryParse(cartonCtrl.text.trim()) ?? 0.1,
                    defaultNylonPerUnit: double.tryParse(nylonCtrl.text.trim()) ?? 1.0,
                    defaultLabelPerUnit: double.tryParse(labelCtrl.text.trim()) ?? 1.0,
                  );
                  setState(() {
                    _items.add(newItem);
                    _syncDefaults();
                  });
                  _saveLocalData();
                  if (_autoSyncOnEveryChange) _pushToCloud();
                  Navigator.pop(ctx);
                  _showMsg(_t('✅ کالای جدید به انبار اضافه شد.', '✅ New item added to warehouse.', '✅ تمت إضافة الصنف للمستودع.'));
                },
                child: Text(_t('افزودن کالا', 'Add Item', 'إضافة الصنف')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _activeDirection,
        child: AlertDialog(
          title: Text(_t('👤 افزودن مشتری جدید', '👤 Add New Customer', '👤 إضافة عميل جديد')),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: _t('نام مشتری / شرکت / فروشگاه *', 'Customer / Company Name *', 'اسم العميل / الشركة *'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
            ElevatedButton(
              onPressed: () {
                final c = ctrl.text.trim();
                if (c.isEmpty) return;
                setState(() {
                  if (!_customers.contains(c)) _customers.add(c);
                  _saleCustomer = c;
                });
                _saveLocalData();
                if (_autoSyncOnEveryChange) _pushToCloud();
                Navigator.pop(ctx);
                _showMsg(_t('✅ مشتری جدید اضافه شد.', '✅ Customer added.', '✅ تمت إضافة العميل.'));
              },
              child: Text(_t('ثبت مشتری', 'Save Customer', 'حفظ العميل')),
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpenseOrDeposit() {
    final rawInputAmt = double.tryParse(_txAmountCtrl.text.trim());
    final title = _txTitleCtrl.text.trim();
    if (rawInputAmt == null || rawInputAmt <= 0 || title.isEmpty) {
      _showMsg(_t('لطفاً مبلغ ($_currUnit) و شرح را وارد کنید.', 'Please enter amount ($_currUnit) and description.', 'يرجى إدخال المبلغ ($_currUnit) والوصف.'));
      return;
    }

    final baseAmt = _fromInputToBaseRial(rawInputAmt);

    final rec = TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: _formMode,
      source: _formSource,
      amountOMR: double.parse(baseAmt.toStringAsFixed(4)),
      hasVat5Percent: _txHasVat,
      date: _txDate,
      topic: _selectedTopic,
      category: _formMode == TxMode.deposit ? 'دریافت تنخواه از شرکت' : _selectedCategory,
      title: title,
      note: _txNoteCtrl.text.trim(),
      createdBy: _currentUser?.displayName ?? 'مدیر',
      customValues: Map<String, String>.from(_selectedCustomValues),
    );

    setState(() {
      _transactions.insert(0, rec);
      _addAuditLog(
        'تنخواه و هزینه',
        '${rec.mode == TxMode.deposit ? "دریافت تنخواه" : "ثبت هزینه"}: ${rec.title} (${rec.category})',
        rec.amountOMR,
      );
      _txAmountCtrl.clear();
      _txTitleCtrl.clear();
      _txNoteCtrl.clear();
      _txHasVat = false;
    });
    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showMsg(_t('✅ در دفتر تنخواه و هزینه‌ها ثبت شد.', '✅ Saved to Petty Cash & Expenses ledger.', '✅ تم الحفظ في دفتر العهدة والمصاريف.'));
  }

  Widget _buildPettyCashAndExpensesTab(AppUserAccount u) {
    final canEdit = u.isSuperAdmin || u.canManagePettyCash;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (canEdit)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t('➕ ثبت هزینه روزانه یا دریافت تنخواه از شرکت', '➕ Record Daily Expense or Petty Cash Deposit', '➕ تسجيل مصروف يومي أو استلام عهدة'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(_t('💸 ثبت هزینه کرد', '💸 Expense', '💸 تسجيل مصروف')),
                        selected: _formMode == TxMode.expense,
                        onSelected: (_) => setState(() => _formMode = TxMode.expense),
                      ),
                      ChoiceChip(
                        label: Text(_t('💰 دریافت تنخواه از شرکت', '💰 Petty Cash Deposit', '💰 استلام عهدة من الشركة')),
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
                          label: Text(_t('از تنخواه شرکت', 'Company Petty Cash', 'من عهدة الشركة')),
                          selected: _formSource == ExpenseSource.petty,
                          onSelected: (_) => setState(() => _formSource = ExpenseSource.petty),
                        ),
                        ChoiceChip(
                          label: Text(_t('از جیب برای کار', 'Out-of-Pocket (Work)', 'من الجيب للعمل')),
                          selected: _formSource == ExpenseSource.pocket,
                          onSelected: (_) => setState(() => _formSource = ExpenseSource.pocket),
                        ),
                        ChoiceChip(
                          label: Text(_t('هزینه شخصی', 'Personal', 'مصروف شخصي')),
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
                          decoration: InputDecoration(
                            labelText: '${_t('مبلغ', 'Amount', 'المبلغ')} ($_currUnit) *',
                            border: const OutlineInputBorder(),
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
                    decoration: InputDecoration(
                      labelText: _t('موضوع / مرکز هزینه', 'Cost Center / Topic', 'مركز التكلفة / الموضوع'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_formMode == TxMode.expense) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      decoration: InputDecoration(
                        labelText: _t('سرفصل هزینه کرد', 'Expense Category', 'فئة المصروف'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_t('شامل ۵٪ مالیات بر ارزش افزوده (VAT 5%) است', 'Includes 5% VAT', 'يشمل ضريبة القيمة المضافة 5%')),
                      value: _txHasVat,
                      onChanged: (v) => setState(() => _txHasVat = v ?? false),
                    ),
                  ],
                  TextField(
                    controller: _txTitleCtrl,
                    decoration: InputDecoration(
                      labelText: _t('عنوان / شرح هزینه یا دریافت *', 'Description / Title *', 'الوصف / العنوان *'),
                      border: const OutlineInputBorder(),
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
                    label: Text(_t('ثبت در دفتر تنخواه و هزینه‌ها', 'Save Transaction', 'حفظ في دفتر العهدة والمصاريف')),
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
                Text(
                  _t('📋 آخرین تراکنش‌های تنخواه و هزینه‌ها:', '📋 Recent Petty Cash Transactions:', '📋 أحدث معاملات العهدة والمصاريف:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (_transactions.isEmpty)
                  Text(_t('هنوز تراکنشی ثبت نشده است.', 'No transactions recorded yet.', 'لم يتم تسجيل أي معاملات بعد.'))
                else
                  ..._transactions.take(15).map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_fmtDate(t.date)} | ${t.topic} | ${t.category} | ${t.createdBy}'),
                        trailing: Text(
                          '${t.mode == TxMode.deposit ? '+' : ''}${_fmtMoneyWithUnit(t.amountOMR)}',
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
    final tollFee = _fromInputToBaseRial(double.tryParse(_prodTollFeeCtrl.text.trim()) ?? 0.0);
    final transport = _fromInputToBaseRial(double.tryParse(_prodTransportCtrl.text.trim()) ?? 0.0);

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
    final rawPrice = double.tryParse(_inbPriceCtrl.text.trim());
    final rawFreight = double.tryParse(_inbFreightCtrl.text.trim()) ?? 0.0;
    if (_selectedInboundItemId == null || qty == null || qty <= 0 || rawPrice == null || rawPrice < 0) {
      _showMsg(_t('لطفاً کالا، مقدار و قیمت واحد را وارد کنید.', 'Please enter item, quantity and unit price.', 'يرجى إدخال الصنف والكمية وسعر الوحدة.'));
      return;
    }
    final price = _fromInputToBaseRial(rawPrice);
    final freight = _fromInputToBaseRial(rawFreight);

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
      createdBy: _currentUser?.displayName ?? 'مدیر',
    );

    setState(() {
      final oldVal = (item.currentQty > 0 ? item.currentQty : 0.0) * item.avgUnitCostOMR;
      final newTotalQty = (item.currentQty > 0 ? item.currentQty : 0.0) + qty;
      if (newTotalQty > 0) {
        item.avgUnitCostOMR = (oldVal + doc.totalLandedCostOMR) / newTotalQty;
      }
      item.currentQty += qty;
      _inbounds.insert(0, doc);
      _addAuditLog('ورود انبار', 'ورود ${_fmtQty(qty)} ${item.unit} ${item.name}', doc.totalLandedCostOMR);
      _inbQtyCtrl.clear();
      _inbFreightCtrl.text = '0';
      _warehouseSubTab = 0;
    });
    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showMsg(_t('✅ ورود به انبار ثبت شد و میانگین موزون بهای تمام‌شده به‌روز گردید.', '✅ Warehouse inbound saved & weighted average cost updated.', '✅ تم تسجيل دخول البضاعة وتحديث متوسط التكلفة.'));
  }

  void _saveProductionBatch() {
    final rawQty = double.tryParse(_prodRawQtyCtrl.text.trim()) ?? 0.0;
    final finQty = double.tryParse(_prodFinQtyCtrl.text.trim()) ?? 0.0;
    final cartonQty = double.tryParse(_prodCartonQtyCtrl.text.trim()) ?? 0.0;
    final nylonQty = double.tryParse(_prodNylonQtyCtrl.text.trim()) ?? 0.0;
    final labelQty = double.tryParse(_prodLabelQtyCtrl.text.trim()) ?? 0.0;
    final tollFee = _fromInputToBaseRial(double.tryParse(_prodTollFeeCtrl.text.trim()) ?? 0.0);
    final transport = _fromInputToBaseRial(double.tryParse(_prodTransportCtrl.text.trim()) ?? 0.0);

    if (rawQty <= 0 || finQty <= 0 || _prodRawId == null || _prodFinId == null) {
      _showMsg(_t('لطفاً مقدار ماده اولیه و تعداد محصول نهایی تولیدشده را وارد کنید.', 'Please enter raw material and finished quantity.', 'يرجى إدخال كمية المواد الخام والمنتج النهائي.'));
      return;
    }

    final rawItem = _items.firstWhere((e) => e.id == _prodRawId!);
    final finItem = _items.firstWhere((e) => e.id == _prodFinId!);
    final cartonItem = _items.firstWhere((e) => e.id == _prodCartonId!);
    final nylonItem = _items.firstWhere((e) => e.id == _prodNylonId!);
    final labelItem = _items.firstWhere((e) => e.id == _prodLabelId!);

    if (rawQty > rawItem.currentQty + 0.0001) {
      _showMsg('❌ خطای کنترلی انبار ۱: موجودی «${rawItem.name}» (${_fmtQty(rawItem.currentQty)} ${rawItem.unit}) کمتر از مقدار مصرفی (${_fmtQty(rawQty)}) است!');
      return;
    }
    if (cartonQty > cartonItem.currentQty + 0.0001) {
      _showMsg('❌ خطای کنترلی انبار ۲: موجودی کارتن (${_fmtQty(cartonItem.currentQty)}) کافی نیست!');
      return;
    }
    if (nylonQty > nylonItem.currentQty + 0.0001) {
      _showMsg('❌ خطای کنترلی انبار ۲: موجودی نایلون (${_fmtQty(nylonItem.currentQty)}) کافی نیست!');
      return;
    }
    if (labelQty > labelItem.currentQty + 0.0001) {
      _showMsg('❌ خطای کنترلی انبار ۲: موجودی لیبل (${_fmtQty(labelItem.currentQty)}) کافی نیست!');
      return;
    }

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
      isFactoryFeePaid: _prodTollPaid,
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
      createdBy: _currentUser?.displayName ?? 'مدیر',
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
      _addAuditLog(
        'تولید و بهای تمام‌شده',
        'تولید ${_fmtQty(finQty)} ${finItem.unit} ${finItem.name}',
        doc.totalBatchCostOMR,
      );

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
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showMsg('✅ تولید ثبت شد! بهای تمام‌شده واحد: ${_fmtMoneyWithUnit(doc.unitCostOMR)}');
  }

  void _saveStockAdjustment() {
    if (_adjustItemId == null) return;
    final delta = double.tryParse(_adjustQtyDeltaCtrl.text.trim());
    final reason = _adjustReasonCtrl.text.trim();
    if (delta == null || delta == 0 || reason.isEmpty) {
      _showMsg(_t('لطفاً مقدار تعدیل/ضایعات و علت را وارد کنید.', 'Please enter adjustment quantity and reason.', 'يرجى إدخال كمية التعديل والسبب.'));
      return;
    }
    final item = _items.firstWhere((e) => e.id == _adjustItemId!);
    if (item.currentQty + delta < -0.0001) {
      _showMsg(_t('❌ موجودی پس از کسر ضایعات نمی‌تواند منفی شود!', '❌ Stock cannot become negative!', '❌ لا يمكن أن يصبح المخزون سالباً!'));
      return;
    }
    setState(() {
      item.currentQty += delta;
      _addAuditLog(
        'تعدیل انبار / ضایعات',
        '${delta < 0 ? "کسر ضایعات" : "افزایش انبارگردانی"} ${item.name} (${_fmtQty(delta.abs())} ${item.unit}) — $reason',
        (delta.abs() * item.avgUnitCostOMR),
      );
      _adjustQtyDeltaCtrl.clear();
      _adjustReasonCtrl.clear();
      _warehouseSubTab = 0;
    });
    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showMsg(_t('✅ سند ضایعات / تعدیل انبارگردانی ثبت شد.', '✅ Stock adjustment saved.', '✅ تم حفظ سند التعديل/التوالف.'));
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
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text(_t('📦 موجودی ۳ انبار', '📦 3 Warehouses Stock', '📦 مخزون المستودعات الثلاثة')),
              selected: _warehouseSubTab == 0,
              onSelected: (_) => setState(() => _warehouseSubTab = 0),
            ),
            if (canWh)
              ChoiceChip(
                label: Text(_t('📥 ورود به انبار ۱ و ۲', '📥 Inbound (Wh 1 & 2)', '📥 إدخال للمستودع ١ و ٢')),
                selected: _warehouseSubTab == 1,
                onSelected: (_) => setState(() => _warehouseSubTab = 1),
              ),
            if (canProd)
              ChoiceChip(
                label: Text(_t('⚙️ تولید کارمزدی (BOM)', '⚙️ BOM Production', '⚙️ التصنيع والتكلفة')),
                selected: _warehouseSubTab == 2,
                onSelected: (_) => setState(() => _warehouseSubTab = 2),
              ),
            if (canWh)
              ChoiceChip(
                label: Text(_t('⚖️ ضایعات / انبارگردانی', '⚖️ Spoilage / Audit', '⚖️ التوالف والجرد')),
                selected: _warehouseSubTab == 3,
                onSelected: (_) => setState(() => _warehouseSubTab = 3),
              ),
            ChoiceChip(
              label: Text('${_t('📄 برگه‌های خروج از انبار', '📄 Warehouse Exit Slips', '📄 سندات إخراج البضاعة')} (${_exitSlips.length})'),
              selected: _warehouseSubTab == 4,
              onSelected: (_) => setState(() => _warehouseSubTab = 4),
            ),
            if (canWh)
              ActionChip(
                label: Text(_t('➕ تعریف کالای جدید', '➕ New Product/Item', '➕ تعريف صنف جديد')),
                onPressed: _showAddNewProductOrItemDialog,
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_warehouseSubTab == 0) ...[
          _buildWarehouseCard(
            _t('🧱 انبار ۱: مواد اولیه اصلی (پنیر بلوکی، کره فله و...)', '🧱 Warehouse 1: Raw Materials', '🧱 مستودع ١: المواد الخام الأساسية'),
            const Color(0xFF0369A1),
            WarehouseType.rawMaterial,
            _rawList,
          ),
          const SizedBox(height: 12),
          _buildWarehouseCard(
            _t('📦 انبار ۲: ملزومات بسته‌بندی (کارتن، نایلون، لیبل و...)', '📦 Warehouse 2: Packaging Supplies', '📦 مستودع ٢: مستلزمات التغليف'),
            const Color(0xFFB45309),
            WarehouseType.packagingSupply,
            _pkgList,
          ),
          const SizedBox(height: 12),
          _buildWarehouseCard(
            _t('🏷️ انبار ۳: محصولات نهایی آماده فروش (با بهای تمام‌شده)', '🏷️ Warehouse 3: Finished Goods (COGS)', '🏷️ مستودع ٣: المنتجات النهائية الجاهزة للبيع'),
            const Color(0xFF0F766E),
            WarehouseType.finishedGood,
            _finList,
          ),
          if (_productions.any((p) => !p.isFactoryFeePaid)) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏭 ${_t('بدهی‌های تسویه‌نشده کارمزد کارخانه', 'Unpaid Factory Toll Fees', 'مستحقات أجور المصنع غير المسددة')} (${_fmtMoneyWithUnit(_totalUnpaidFactoryTollOMR)}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                    const Divider(),
                    ..._productions.where((p) => !p.isFactoryFeePaid).map((p) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${p.finishedItemName} (${_fmtDate(p.date)})'),
                          subtitle: Text('${_t('کارمزد کارخانه:', 'Factory Toll:', 'أجرة المصنع:')} ${_fmtMoneyWithUnit(p.factoryTollFeeOMR)}'),
                          trailing: canProd
                              ? ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      p.isFactoryFeePaid = true;
                                      _addAuditLog('تسویه کارخانه', 'پرداخت کارمزد کارخانه بابت ${p.finishedItemName}',
                                          p.factoryTollFeeOMR);
                                    });
                                    _saveLocalData();
                                    if (_autoSyncOnEveryChange) _pushToCloud();
                                    _showMsg(_t('✅ کارمزد این پارت تسویه شد.', '✅ Factory toll settled.', '✅ تم تسديد أجرة المصنع.'));
                                  },
                                  child: Text(_t('ثبت تسویه با کارخانه', 'Settle Payable', 'تسديد للمصنع')),
                                )
                              : Text(_t('تسویه‌نشده', 'Unpaid', 'غير مسدد')),
                        )),
                  ],
                ),
              ),
            ),
          ],
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
                        label: Text(_t('🧱 انبار ۱ (مواد اولیه)', '🧱 Warehouse 1 (Raw)', '🧱 مستودع ١ (مواد خام)')),
                        selected: _inboundWhTarget == WarehouseType.rawMaterial,
                        onSelected: (_) {
                          setState(() {
                            _inboundWhTarget = WarehouseType.rawMaterial;
                            _syncDefaults();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(_t('📦 انبار ۲ (کارتن/نایلون/لیبل)', '📦 Warehouse 2 (Packaging)', '📦 مستودع ٢ (تغليف)')),
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
                    decoration: InputDecoration(
                      labelText: _t('انتخاب کالا / ملزومات ورودی', 'Select Inbound Item', 'اختر الصنف الوارد'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inbQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _t('مقدار ورودی *', 'Quantity *', 'الكمية الواردة *'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inbPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '${_t('قیمت خرید واحد', 'Unit Price', 'سعر الوحدة')} ($_currUnit) *',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inbFreightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '${_t('هزینه حمل بار', 'Freight Cost', 'تكلفة الشحن')} ($_currUnit)',
                            border: const OutlineInputBorder(),
                          ),
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
                    child: Text(_t('ثبت ورود و محاسبه میانگین موزون بهای تمام‌شده', 'Save Inbound & Recalculate Avg Cost', 'حفظ الإدخال وحساب متوسط التكلفة')),
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
                  Text(
                    _t('⚙️ ثبت تولید کارمزدی (مجهز به قفل کنترل موجودی منفی انبار ۱ و ۲):', '⚙️ Record BOM Production Batch (with Negative Stock Guard):', '⚙️ تسجيل دفعة الإنتاج وحساب التكلفة:'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _prodRawId,
                          items: _rawList
                              .map((r) => DropdownMenuItem<String>(
                                    value: r.id,
                                    child: Text('${r.name} (${_fmtQty(r.currentQty)})'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _prodRawId = v),
                          decoration: InputDecoration(labelText: _t('۱. ماده اولیه از انبار ۱', '1. Raw Material (Wh 1)', '١. المادة الخام (مستودع ١)'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodRawQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: _t('مقدار مصرفی (Kg)', 'Used Qty (Kg)', 'الكمية المستهلكة'), border: const OutlineInputBorder()),
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
                          decoration: InputDecoration(labelText: _t('۲. محصول نهایی (انبار ۳)', '2. Finished Product (Wh 3)', '٢. المنتج النهائي (مستودع ٣)'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodFinQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => _autoCalcBom(v),
                          decoration: InputDecoration(labelText: _t('تعداد بسته تولیدی', 'Produced Units', 'عدد العبوات المنتجة'), border: const OutlineInputBorder()),
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
                          decoration: InputDecoration(labelText: _t('کارتن مصرفی (انبار ۲)', 'Cartons Used', 'الكرتون المستهلك'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodNylonQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: _t('نایلون مصرفی (انبار ۲)', 'Nylon Used', 'النايلون المستهلك'), border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodLabelQtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: _t('لیبل مصرفی (انبار ۲)', 'Labels Used', 'الملصقات المستهلكة'), border: const OutlineInputBorder()),
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
                          decoration: InputDecoration(labelText: '${_t('کارمزد کارخانه', 'Factory Toll Fee', 'أجرة المصنع')} ($_currUnit)', border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodTransportCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: '${_t('هزینه حمل تولید', 'Transport Cost', 'تكلفة النقل')} ($_currUnit)', border: const OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t('کارمزد این پارت به کارخانه پرداخت شده است', 'Factory toll fee is paid in cash', 'تم دفع أجرة المصنع نقداً')),
                    value: _prodTollPaid,
                    onChanged: (v) => setState(() => _prodTollPaid = v ?? false),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '📊 ${_t('کل بهای تمام‌شده پارت:', 'Total Batch Cost:', 'إجمالي تكلفة الدفعة:')} ${_fmtMoneyWithUnit(liveCost['totalBatchCost']!)}\n'
                      '🏷️ ${_t('بهای تمام‌شده هر بسته:', 'Unit Cost:', 'تكلفة العبوة:')} ${_fmtMoneyWithUnit(liveCost['unitCost']!)} | ${_t('هر ۱ کیلو:', 'Per 1 Kg:', 'لكل ١ كجم:')} ${_fmtMoneyWithUnit(liveCost['costPerKg']!)}',
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
                    child: Text(_t('ثبت سند تولید و بهای تمام‌شده محصول', 'Save Production & Update COGS', 'حفظ الإنتاج وتحديث التكلفة')),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_warehouseSubTab == 3 && canWh) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t('⚖️ ثبت سند ضایعات انبار یا تعدیل انبارگردانی:', '⚖️ Record Stock Spoilage or Audit Adjustment:', '⚖️ تسجيل توالف المستودع أو تعديل الجرد:'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _adjustItemId,
                    items: _items
                        .map((i) => DropdownMenuItem<String>(
                              value: i.id,
                              child: Text('${i.name} (${_fmtQty(i.currentQty)} ${i.unit})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _adjustItemId = v),
                    decoration: InputDecoration(labelText: _t('انتخاب کالا از هر یک از ۳ انبار', 'Select Item', 'اختر الصنف'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _adjustQtyDeltaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: _t('مقدار تغییر (مثلاً -3 برای کسر ضایعات یا 5 برای اضافه انبارگردانی) *', 'Quantity Delta (e.g. -3 or +5) *', 'مقدار التغيير (مثال: -3 أو +5) *'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _adjustReasonCtrl,
                    decoration: InputDecoration(
                      labelText: _t('علت ضایعات / شماره صورت‌جلسه انبارگردانی *', 'Reason / Audit Reference *', 'سبب التوالف / رقم محضر الجرد *'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _saveStockAdjustment,
                    child: Text(_t('ثبت سند تعدیل / ضایعات انبار', 'Save Stock Adjustment', 'حفظ سند التعديل')),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_warehouseSubTab == 4) ...[
          _buildWarehouseExitSlipsSectionCard(),
        ],
      ],
    );
  }

  Widget _buildWarehouseExitSlipsSectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 ${_t('دفتر برگه‌های خروج کالا از انبار (صادرشده خودکار به ازای هر سفارش مشتری)', 'Warehouse Exit Slips Register (Auto-Issued Per Customer Order)', 'سجل سندات إخراج البضاعة من المستودع (الصادرة تلقائياً لكل طلب عميل)')}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
            ),
            const Divider(),
            if (_exitSlips.isEmpty)
              Text(_t(
                'هنوز برگه خروجی صادر نشده است. به محض ثبت هر سفارش/فاکتور فروش برای مشتری، سیستم به صورت خودکار برگه خروج معادل آن را صادر می‌کند.',
                'No warehouse exit slips issued yet. Whenever a customer order/sale is saved, an Exit Slip is automatically generated here.',
                'لم يتم إصدار سندات إخراج بعد. عند تسجيل أي طلب عميل يتم إصدار سند إخراج تلقائياً.',
              ))
            else
              ..._exitSlips.map((slip) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '📦 ${slip.slipNumber} — 👤 ${slip.customerName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Text(
                              _fmtDate(slip.issueDate),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🏷️ ${slip.itemName} | ${_t('تعداد:', 'Qty:', 'الكمية:')} ${_fmtQty(slip.qty)} ${slip.unit} (${_fmtQty(slip.totalWeightKg)} Kg) | 💰 ${_fmtMoneyWithUnit(slip.totalAmountBase)}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        Text(
                          '🚚 ${_t('راننده/تحویل‌گیرنده:', 'Driver/Receiver:', 'السائق/المستلم:')} ${slip.driverOrReceiverName} | 📌 ${slip.deliveryStatus}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _printOrSaveWarehouseExitSlip(slip),
                              icon: const Icon(Icons.print, size: 16),
                              label: Text(_t('چاپ رسمی / ذخیره برگه خروج', 'Print / Save Slip', 'طباعة / حفظ سند الإخراج')),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () => _showExitSlipPreviewDialog(slip),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: Text(_t('مشاهده جزئیات', 'View Details', 'عرض التفاصيل')),
                            ),
                            if (slip.deliveryStatus != 'تحویل قطعی به مشتری شد')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                onPressed: () {
                                  setState(() {
                                    slip.deliveryStatus = 'تحویل قطعی به مشتری شد';
                                    _addAuditLog('انبار و ارسال', 'تایید تحویل قطعی برگه خروج ${slip.slipNumber} به ${slip.customerName}', slip.totalAmountBase);
                                  });
                                  _saveLocalData();
                                  if (_autoSyncOnEveryChange) _pushToCloud();
                                  _showMsg(_t('✅ وضعیت برگه خروج به «تحویل قطعی به مشتری» تغییر یافت.', '✅ Exit slip marked as Delivered.', '✅ تم تحديث حالة السند إلى تم التسليم.'));
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(_t('ثبت تحویل قطعی به مشتری', 'Mark Delivered', 'تأكيد التسليم للعميل')),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
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
                    '${_t('بهای تمام‌شده واحد:', 'Avg Unit Cost:', 'متوسط تكلفة الوحدة:')} ${_fmtMoneyWithUnit(item.avgUnitCostOMR)}'
                    '${whType == WarehouseType.finishedGood ? ' | ${_t('قیمت فروش:', 'Sale Price:', 'سعر البيع:')} ${_fmtMoneyWithUnit(item.defaultSalePriceOMR)}' : ''}',
                  ),
                  trailing: Text(
                    '${_t('موجودی:', 'Stock:', 'المخزون:')} ${_fmtQty(item.currentQty)} ${item.unit}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _saveSaleOrReturnInvoice() {
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final rawPrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final rawDeliv = double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0;
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;

    if (_saleFinId == null || qty <= 0 || rawPrice < 0) {
      _showMsg(_t('لطفاً محصول، تعداد و قیمت واحد را وارد کنید.', 'Please enter product, quantity and unit price.', 'يرجى إدخال المنتج والكمية وسعر الوحدة.'));
      return;
    }

    final price = _fromInputToBaseRial(rawPrice);
    final deliv = _fromInputToBaseRial(rawDeliv);
    final finItem = _items.firstWhere((e) => e.id == _saleFinId!);

    if (!_isSaleReturnMode && qty > finItem.currentQty + 0.0001) {
      _showMsg(
        '❌ ${_t('خطای کنترلی انبار ۳: موجودی', 'Warehouse 3 Stock Error: Available', 'خطأ مخزون المستودع ٣: المتوفر')} «${finItem.name}» (${_fmtQty(finItem.currentQty)} ${finItem.unit}) < (${_fmtQty(qty)})!',
      );
      return;
    }

    final baseRev = qty * price;
    final totalWithVat = _saleHasVat ? baseRev * 1.05 : baseRev;
    final isCash = _salePaymentStatus.contains('نقدی');
    final nextSlipNo = 'EXIT-${1001 + _exitSlips.length}';

    final doc = SaleProfitDoc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exitSlipNumber: nextSlipNo,
      date: DateTime.now(),
      finishedItemId: finItem.id,
      finishedItemName: finItem.name,
      unit: finItem.unit,
      qtySold: qty,
      unitSalePriceOMR: price,
      unitCogsOMR: finItem.avgUnitCostOMR,
      deliveryExpenseOMR: deliv,
      hasVat5Percent: _saleHasVat,
      customerName: _saleCustomer ?? 'مشتری بازار عمان',
      paymentStatus: _isSaleReturnMode ? 'مرجوعی / برگشت از فروش' : _salePaymentStatus,
      paidAmountOMR: (_isSaleReturnMode || isCash) ? totalWithVat : 0.0,
      partnerSplitDivisor: divisor < 1 ? 1 : divisor,
      isReturnDoc: _isSaleReturnMode,
      createdBy: _currentUser?.displayName ?? 'مدیر',
    );

    late WarehouseExitSlip issuedSlip;

    setState(() {
      if (_isSaleReturnMode) {
        finItem.currentQty += qty;
      } else {
        finItem.currentQty -= qty;
      }
      _sales.insert(0, doc);
      issuedSlip = _issueWarehouseExitSlip(doc, finItem);

      _addAuditLog(
        _isSaleReturnMode ? 'برگشت از فروش' : 'سفارش فروش و صدور برگه خروج',
        '${_isSaleReturnMode ? "مرجوعی" : "فروش"} ${_fmtQty(qty)} ${finItem.unit} ${finItem.name} به ${doc.customerName} (برگه خروج: ${issuedSlip.slipNumber})',
        doc.totalRevenueOMR.abs(),
      );
      _saleQtyCtrl.clear();
      _saleDeliveryCostCtrl.text = '0';
      _isSaleReturnMode = false;
    });

    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showExitSlipPreviewDialog(issuedSlip);
  }

  Widget _buildSalesProfitAndPartnerTab(AppUserAccount u) {
    final finItem = _finList.firstWhere((e) => e.id == _saleFinId, orElse: () => _finList.first);
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final salePriceBase = _fromInputToBaseRial(double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0);
    final delivCostBase = _fromInputToBaseRial(double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0);
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;
    final safeDivisor = divisor < 1 ? 1 : divisor;

    final totalRev = qty * salePriceBase;
    final totalCogs = (qty * finItem.avgUnitCostOMR) + delivCostBase;
    final netProfit = totalRev - totalCogs;
    final marginPct = totalRev > 0 ? (netProfit / totalRev) * 100.0 : 0.0;
    final myShare = netProfit / safeDivisor;

    final unpaidSales = _sales.where((s) => s.remainingReceivableOMR > 0.0005).toList();

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
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(_t('🛒 ثبت سفارش فروش + صدور خودکار برگه خروج انبار', '🛒 New Customer Order + Auto Exit Slip', '🛒 تسجيل طلب بيع + إصدار سند إخراج تلقائي')),
                            selected: !_isSaleReturnMode,
                            onSelected: (_) => setState(() => _isSaleReturnMode = false),
                          ),
                          ChoiceChip(
                            label: Text(_t('↩️ برگشت از فروش (مرجوعی)', '↩️ Sales Return', '↩️ مرتجع مبيعات')),
                            selected: _isSaleReturnMode,
                            onSelected: (_) => setState(() => _isSaleReturnMode = true),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddCustomerDialog,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: Text(_t('+ مشتری جدید', '+ New Customer', '+ عميل جديد')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _saleCustomer,
                  items: _customers
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text('👤 $c')))
                      .toList(),
                  onChanged: (v) => setState(() => _saleCustomer = v),
                  decoration: InputDecoration(
                    labelText: _t('انتخاب مشتری سفارش‌دهنده', 'Select Customer', 'اختر العميل'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _saleFinId,
                  items: _finList
                      .map((f) => DropdownMenuItem<String>(
                            value: f.id,
                            child: Text('${f.name} (${_t('موجودی:', 'Stock:', 'المخزون:')} ${_fmtQty(f.currentQty)} | COGS: ${_fmtMoneyWithUnit(f.avgUnitCostOMR)})'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _saleFinId = v;
                      final sel = _finList.firstWhere((e) => e.id == v);
                      _salePriceCtrl.text = _fmtOMR(sel.defaultSalePriceOMR);
                    });
                  },
                  decoration: InputDecoration(
                    labelText: _t('انتخاب محصول از انبار ۳', 'Select Product (Warehouse 3)', 'اختر المنتج (مستودع ٣)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _saleQtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: _t('تعداد سفارش / خروج از انبار *', 'Order Quantity *', 'الكمية المطلوبة *'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _salePriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: '${_t('فی فروش واحد', 'Unit Sale Price', 'سعر بيع الوحدة')} ($_currUnit) *',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _saleCustomerAddressCtrl,
                        decoration: InputDecoration(
                          labelText: _t('آدرس تحویل / تلفن مشتری (درج در برگه خروج)', 'Delivery Address / Phone (Exit Slip)', 'عنوان التسليم / هاتف العميل (في سند الإخراج)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _saleDriverNameCtrl,
                        decoration: InputDecoration(
                          labelText: _t('نام راننده / تحویل‌گیرنده بار', 'Driver / Receiver Name', 'اسم السائق / المستلم'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _salePaymentStatus,
                  items: [
                    DropdownMenuItem(value: 'نقدی / واریز بانکی', child: Text(_t('نقدی / واریز بانکی (تسویه‌شده)', 'Cash / Bank Transfer (Paid)', 'نقدي / تحويل بنكي (مسدد)'))),
                    DropdownMenuItem(value: 'نسیه / طلب از مشتری', child: Text(_t('نسیه / طلب از مشتری (حساب دریافتنی)', 'Credit / Accounts Receivable', 'آجل / ذمم مدينة على العميل'))),
                  ],
                  onChanged: (v) => setState(() => _salePaymentStatus = v!),
                  decoration: InputDecoration(
                    labelText: _t('وضعیت تسویه سفارش', 'Payment Status', 'حالة الدفع'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t('افزودن ۵٪ مالیات بر ارزش افزوده (VAT 5%) به فاکتور', 'Add 5% VAT to Invoice', 'إضافة ضريبة القيمة المضافة 5% للفاتورة')),
                  value: _saleHasVat,
                  onChanged: (v) => setState(() => _saleHasVat = v ?? false),
                ),
                Text(_t('🤝 تقسیم سود این بار بین شما و شریک:', '🤝 Partner Profit Split for this Order:', '🤝 تقسيم ربح هذه الدفعة مع الشريك:'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(_t('۱۰۰٪ خودم', '100% Mine', '١٠٠٪ لي')),
                      selected: _salePartnerDivisor == 1,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 1),
                    ),
                    ChoiceChip(
                      label: Text(_t('تقسیم بر ۲', 'Split ÷ 2', 'تقسيم على ٢')),
                      selected: _salePartnerDivisor == 2,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 2),
                    ),
                    ChoiceChip(
                      label: Text(_t('تقسیم بر ۳', 'Split ÷ 3', 'تقسيم على ٣')),
                      selected: _salePartnerDivisor == 3,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 3),
                    ),
                    ChoiceChip(
                      label: Text(_t('عدد دلخواه', 'Custom Split', 'عدد مخصص')),
                      selected: _salePartnerDivisor == 0,
                      onSelected: (_) => setState(() => _salePartnerDivisor = 0),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: netProfit >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${netProfit >= 0 ? _t('✅ سفارش در سود', '✅ Profitable Order', '✅ الطلب رابح') : _t('⚠️ هشدار فروش در زیان!', '⚠️ Loss Warning!', '⚠️ تحذير بيع بخسارة!')} | ${_t('حاشیه سود:', 'Margin:', 'هامش الربح:')} ${marginPct.toStringAsFixed(1)}%\n'
                    '${_t('مبلغ فروش:', 'Revenue:', 'إجمالي البيع:')} ${_fmtMoneyWithUnit(totalRev)} | COGS: ${_fmtMoneyWithUnit(totalCogs)}\n'
                    '${_t('سود ناخالص:', 'Gross Profit:', 'الربح الإجمالي:')} ${_fmtMoneyWithUnit(netProfit)}  |  👤 ${_t('سهم شما', 'Your Share', 'حصتك')} (÷$safeDivisor): ${_fmtMoneyWithUnit(myShare)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaleReturnMode ? Colors.orange[800] : const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saveSaleOrReturnInvoice,
                  icon: const Icon(Icons.print),
                  label: Text(_isSaleReturnMode
                      ? _t('ثبت برگشت از فروش و بازگرداندن کالا به انبار ۳', 'Save Sales Return & Restore Stock', 'حفظ مرتجع المبيعات وإعادة البضاعة للمستودع')
                      : _t('ثبت سفارش فروش + صدور خودکار «برگه خروج کالا از انبار»', 'Save Order & Auto-Issue Warehouse Exit Slip', 'تسجيل الطلب وإصدار سند إخراج البضاعة تلقائياً')),
                ),
              ],
            ),
          ),
        ),

        if (unpaidSales.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💵 ${_t('مطالبات نسیه از مشتریان', 'Customer Accounts Receivable', 'ذمم العملاء غير المسددة')} (${_fmtMoneyWithUnit(_totalUnpaidReceivablesOMR)}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                  const Divider(),
                  ...unpaidSales.map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('👤 ${s.customerName} — ${s.finishedItemName} (${s.exitSlipNumber})'),
                        subtitle: Text('${_t('مانده بدهی مشتری:', 'Remaining Balance:', 'الرصيد المتبقي:')} ${_fmtMoneyWithUnit(s.remainingReceivableOMR)}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              final rem = s.remainingReceivableOMR;
                              s.paidAmountOMR = s.totalInvoiceWithVatOMR;
                              s.paymentStatus = 'تسویه‌شده';
                              _addAuditLog('دریافت مطالبات', 'تسویه حساب نسیه مشتری ${s.customerName}', rem);
                            });
                            _saveLocalData();
                            if (_autoSyncOnEveryChange) _pushToCloud();
                            _showMsg(_t('✅ بدهی مشتری تسویه شد.', '✅ Customer receivable settled.', '✅ تم تسديد مديونية العميل.'));
                          },
                          child: Text(_t('ثبت دریافت وجه', 'Mark Paid', 'تسجيل الدفع')),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
        _buildWarehouseExitSlipsSectionCard(),
      ],
    );
  }

  // ==========================================================================
  // تب ۴: سیستم «گزارش‌ساز پویا با انعطاف کامل» + انتقال به اکسل + چاپ رسمی + P&L دوطبقه (با اعمال واحد پول انتخابی)
  // ==========================================================================
  bool _inRepDateRange(DateTime d) {
    final f = DateTime.tryParse(_repFromDateCtrl.text.trim()) ?? _repFromDate;
    final t = DateTime.tryParse(_repToDateCtrl.text.trim()) ?? _repToDate;
    if (f != null) {
      final s = DateTime(f.year, f.month, f.day);
      if (d.isBefore(s)) return false;
    }
    if (t != null) {
      final e = DateTime(t.year, t.month, t.day, 23, 59, 59);
      if (d.isAfter(e)) return false;
    }
    return true;
  }

  void _setQuickRepDays(int? days) {
    setState(() {
      if (days == null) {
        _repFromDate = null;
        _repToDate = null;
        _repFromDateCtrl.clear();
        _repToDateCtrl.clear();
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = today.subtract(Duration(days: days - 1));
        _repFromDate = start;
        _repToDate = today;
        _repFromDateCtrl.text = _fmtDate(start);
        _repToDateCtrl.text = _fmtDate(today);
      }
    });
  }

  List<CustomReportRow> _generateDynamicReportRows() {
    final rawRows = <CustomReportRow>[];

    if (_incExpensesInRep) {
      for (final t in _transactions) {
        if (!_inRepDateRange(t.date)) continue;
        rawRows.add(CustomReportRow(
          date: t.date,
          docId: t.id,
          docType: t.mode == TxMode.deposit ? 'دریافت تنخواه' : 'هزینه تنخواه/جاری',
          titleOrItem: t.title,
          partyOrTopic: t.topic,
          categoryOrWh: t.category,
          qty: 1,
          unit: 'مورد',
          unitPriceOrCostOMR: t.amountOMR,
          totalAmountOMR: t.amountOMR,
          cogsOMR: 0,
          profitOMR: 0,
          statusOrUser: t.createdBy,
        ));
      }
    }

    if (_incInboundsInRep) {
      for (final i in _inbounds) {
        if (!_inRepDateRange(i.date)) continue;
        rawRows.add(CustomReportRow(
          date: i.date,
          docId: i.id,
          docType: 'ورود به انبار خرید',
          titleOrItem: i.itemName,
          partyOrTopic: 'تامین‌کننده انبار',
          categoryOrWh: i.warehouse == WarehouseType.rawMaterial ? 'انبار ۱ (مواد اولیه)' : 'انبار ۲ (ملزومات)',
          qty: i.qty,
          unit: i.unit,
          unitPriceOrCostOMR: i.landedUnitCostOMR,
          totalAmountOMR: i.totalLandedCostOMR,
          cogsOMR: i.totalLandedCostOMR,
          profitOMR: 0,
          statusOrUser: i.createdBy,
        ));
      }
    }

    if (_incProductionsInRep) {
      for (final p in _productions) {
        if (!_inRepDateRange(p.date)) continue;
        rawRows.add(CustomReportRow(
          date: p.date,
          docId: p.id,
          docType: 'تولید کارمزدی (BOM)',
          titleOrItem: p.finishedItemName,
          partyOrTopic: 'کارخانه طرف قرارداد',
          categoryOrWh: 'انبار ۳ (محصول نهایی)',
          qty: p.finishedQtyProduced,
          unit: p.finishedUnit,
          unitPriceOrCostOMR: p.unitCostOMR,
          totalAmountOMR: p.totalBatchCostOMR,
          cogsOMR: p.totalBatchCostOMR,
          profitOMR: 0,
          statusOrUser: p.isFactoryFeePaid ? 'کارمزد تسویه‌شده' : 'کارمزد بدهکار',
        ));
      }
    }

    if (_incSalesInRep) {
      for (final s in _sales) {
        if (!_inRepDateRange(s.date)) continue;
        rawRows.add(CustomReportRow(
          date: s.date,
          docId: s.exitSlipNumber.isNotEmpty ? s.exitSlipNumber : s.id,
          docType: s.isReturnDoc ? 'برگشت از فروش' : 'فروش (${s.exitSlipNumber})',
          titleOrItem: s.finishedItemName,
          partyOrTopic: s.customerName,
          categoryOrWh: 'فروش بازار عمان',
          qty: s.qtySold,
          unit: s.unit,
          unitPriceOrCostOMR: s.unitSalePriceOMR,
          totalAmountOMR: s.totalRevenueOMR,
          cogsOMR: s.totalCogsOMR,
          profitOMR: s.netProfitOrLossOMR,
          statusOrUser: s.paymentStatus,
        ));
      }
    }

    rawRows.sort((a, b) => b.date.compareTo(a.date));

    if (_customGroupBy == 'none') {
      return rawRows;
    }

    final Map<String, CustomReportRow> grouped = {};
    for (final r in rawRows) {
      String key = r.titleOrItem;
      String groupTitle = r.titleOrItem;
      if (_customGroupBy == 'by_party') {
        key = '${r.partyOrTopic}__${r.docType}';
        groupTitle = r.partyOrTopic;
      } else if (_customGroupBy == 'by_category') {
        key = '${r.categoryOrWh}__${r.docType}';
        groupTitle = r.categoryOrWh;
      } else if (_customGroupBy == 'by_date') {
        key = '${_fmtDate(r.date)}__${r.docType}';
        groupTitle = _fmtDate(r.date);
      } else {
        key = '${r.titleOrItem}__${r.docType}';
        groupTitle = r.titleOrItem;
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = CustomReportRow(
          date: r.date,
          docId: 'تجمیعی',
          docType: r.docType,
          titleOrItem: groupTitle,
          partyOrTopic: r.partyOrTopic,
          categoryOrWh: r.categoryOrWh,
          qty: r.qty,
          unit: r.unit,
          unitPriceOrCostOMR: r.unitPriceOrCostOMR,
          totalAmountOMR: r.totalAmountOMR,
          cogsOMR: r.cogsOMR,
          profitOMR: r.profitOMR,
          statusOrUser: '۱ سند',
        );
      } else {
        final ex = grouped[key]!;
        final newQty = ex.qty + r.qty;
        final newTotal = ex.totalAmountOMR + r.totalAmountOMR;
        final count = (int.tryParse(ex.statusOrUser.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1) + 1;
        grouped[key] = CustomReportRow(
          date: r.date.isAfter(ex.date) ? r.date : ex.date,
          docId: 'تجمیعی ($count ردیف)',
          docType: ex.docType,
          titleOrItem: ex.titleOrItem,
          partyOrTopic: ex.partyOrTopic,
          categoryOrWh: ex.categoryOrWh,
          qty: newQty,
          unit: ex.unit,
          unitPriceOrCostOMR: newQty > 0 ? newTotal / newQty : ex.unitPriceOrCostOMR,
          totalAmountOMR: newTotal,
          cogsOMR: ex.cogsOMR + r.cogsOMR,
          profitOMR: ex.profitOMR + r.profitOMR,
          statusOrUser: '$count سند تجمیع‌شده',
        );
      }
    }

    return grouped.values.toList();
  }

  String _buildCustomDelimitedTable(List<CustomReportRow> rows, {required String sep}) {
    final headers = <String>[_t('ردیف', 'Row', 'م')];
    if (_colDate) headers.add(_t('تاریخ', 'Date', 'التاريخ'));
    if (_colType) headers.add(_t('نوع سند', 'Doc Type', 'نوع المستند'));
    if (_colTitle) headers.add(_t('شرح / کالا', 'Item / Title', 'الصنف / الوصف'));
    if (_colParty) headers.add(_t('طرف حساب / موضوع', 'Customer / Party', 'العميل / الجهة'));
    if (_colCategory) headers.add(_t('سرفصل / انبار', 'Category / Warehouse', 'الفئة / المستودع'));
    if (_colQty) headers.add(_t('مقدار / تعداد', 'Quantity', 'الكمية'));
    if (_colUnitPrice) headers.add('${_t('فی واحد', 'Unit Price', 'سعر الوحدة')} ($_currUnit)');
    if (_colTotalAmount) headers.add('${_t('مبلغ کل', 'Total Amount', 'المبلغ الإجمالي')} ($_currUnit)');
    if (_colCogsAndProfit) {
      headers.add('COGS ($_currUnit)');
      headers.add('${_t('سود یا زیان', 'Profit/Loss', 'الربح/الخسارة')} ($_currUnit)');
    }
    if (_colUserAndStatus) headers.add(_t('وضعیت / ثبت‌کننده', 'Status / User', 'الحالة / المستخدم'));

    final lines = <String>[headers.join(sep)];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final cols = <String>[(i + 1).toString()];
      if (_colDate) cols.add(_fmtDate(r.date));
      if (_colType) cols.add(r.docType.replaceAll(sep, ' '));
      if (_colTitle) cols.add(r.titleOrItem.replaceAll(sep, ' '));
      if (_colParty) cols.add(r.partyOrTopic.replaceAll(sep, ' '));
      if (_colCategory) cols.add(r.categoryOrWh.replaceAll(sep, ' '));
      if (_colQty) cols.add('${_fmtQty(r.qty)} ${r.unit}');
      if (_colUnitPrice) cols.add(_fmtOMR(r.unitPriceOrCostOMR));
      if (_colTotalAmount) cols.add(_fmtOMR(r.totalAmountOMR));
      if (_colCogsAndProfit) {
        cols.add(_fmtOMR(r.cogsOMR));
        cols.add(_fmtOMR(r.profitOMR));
      }
      if (_colUserAndStatus) cols.add(r.statusOrUser.replaceAll(sep, ' '));
      lines.add(cols.join(sep));
    }
    return lines.join('\n');
  }

  void _copyCustomReportToExcel(List<CustomReportRow> rows) {
    if (rows.isEmpty) {
      _showMsg(_t('هیچ رکوردی در گزارش فعلی وجود ندارد.', 'No records in current report.', 'لا توجد سجلات في التقرير الحالي.'));
      return;
    }
    final tsv = _buildCustomDelimitedTable(rows, sep: '\t');
    Clipboard.setData(ClipboardData(text: tsv));
    _showMsg(_t('✅ جدول گزارش سفارشی کپی شد! در نرم‌افزار Excel کلید Ctrl+V را بزنید.', '✅ Copied! Press Ctrl+V in Excel.', '✅ تم نسخ الجدول! اضغط Ctrl+V في برنامج إكسل.'));
  }

  Future<void> _exportCustomReportToCSVFile(List<CustomReportRow> rows) async {
    if (rows.isEmpty) {
      _showMsg(_t('هیچ رکوردی در گزارش فعلی وجود ندارد.', 'No records in current report.', 'لا توجد سجلات في التقرير الحالي.'));
      return;
    }
    final csv = '\uFEFF${_buildCustomDelimitedTable(rows, sep: ',')}';
    final fileName = 'Oman_ERP_Report_${_fmtDate(DateTime.now())}.csv';
    try {
      final f = File('${Directory.current.path}/$fileName');
      await f.writeAsString(csv, encoding: utf8);
      _showMsg('✅ فایل اکسل ($fileName) ذخیره شد.');
    } catch (_) {
      Clipboard.setData(ClipboardData(text: csv));
      _showMsg('✅ فایل CSV در حافظه کپی شد.');
    }
  }

  Future<void> _printOfficialReport(List<CustomReportRow> rows) async {
    if (rows.isEmpty) {
      _showMsg(_t('هیچ رکوردی برای چاپ وجود ندارد.', 'No records to print.', 'لا توجد سجلات للطباعة.'));
      return;
    }
    final repTitle = _customRepTitleCtrl.text.trim().isEmpty
        ? 'گزارش رسمی مالی، انبار و سفارشات'
        : _customRepTitleCtrl.text.trim();
    final sumAmount = rows.fold(0.0, (s, r) => s + r.totalAmountOMR);
    final sumProfit = rows.fold(0.0, (s, r) => s + r.profitOMR);
    final dirStr = _lang == AppLang.en ? 'ltr' : 'rtl';
    final alignStr = _lang == AppLang.en ? 'left' : 'right';

    final thList = <String>['<th>#</th>'];
    if (_colDate) thList.add('<th>${_t('تاریخ', 'Date', 'التاريخ')}</th>');
    if (_colType) thList.add('<th>${_t('نوع سند', 'Type', 'النوع')}</th>');
    if (_colTitle) thList.add('<th>${_t('شرح / کالا', 'Item / Title', 'الصنف')}</th>');
    if (_colParty) thList.add('<th>${_t('طرف حساب / موضوع', 'Party', 'العميل')}</th>');
    if (_colCategory) thList.add('<th>${_t('سرفصل / انبار', 'Category', 'المستودع')}</th>');
    if (_colQty) thList.add('<th>${_t('مقدار', 'Qty', 'الكمية')}</th>');
    if (_colUnitPrice) thList.add('<th>${_t('فی واحد', 'Unit Price', 'سعر الوحدة')} ($_currUnit)</th>');
    if (_colTotalAmount) thList.add('<th>${_t('مبلغ کل', 'Total', 'الإجمالي')} ($_currUnit)</th>');
    if (_colCogsAndProfit) thList.add('<th>${_t('سود/زیان', 'Profit/Loss', 'الربح/الخسارة')} ($_currUnit)</th>');
    if (_colUserAndStatus) thList.add('<th>${_t('وضعیت', 'Status', 'الحالة')}</th>');

    final trList = <String>[];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final tds = <String>['<td>${i + 1}</td>'];
      if (_colDate) tds.add('<td>${_fmtDate(r.date)}</td>');
      if (_colType) tds.add('<td>${r.docType}</td>');
      if (_colTitle) tds.add('<td><b>${r.titleOrItem}</b></td>');
      if (_colParty) tds.add('<td>${r.partyOrTopic}</td>');
      if (_colCategory) tds.add('<td>${r.categoryOrWh}</td>');
      if (_colQty) tds.add('<td>${_fmtQty(r.qty)} ${r.unit}</td>');
      if (_colUnitPrice) tds.add('<td>${_fmtOMR(r.unitPriceOrCostOMR)}</td>');
      if (_colTotalAmount) tds.add('<td><b>${_fmtOMR(r.totalAmountOMR)}</b></td>');
      if (_colCogsAndProfit) tds.add('<td>${_fmtOMR(r.profitOMR)}</td>');
      if (_colUserAndStatus) tds.add('<td>${r.statusOrUser}</td>');
      trList.add('<tr>${tds.join('')}</tr>');
    }

    final htmlDoc = '''<!DOCTYPE html>
<html lang="${_lang.name}" dir="$dirStr">
<head>
<meta charset="UTF-8">
<title>$repTitle</title>
<style>
  body { font-family: Tahoma, Arial, sans-serif; margin: 24px; color: #0f172a; }
  .header { border-bottom: 2px solid #0f766e; padding-bottom: 12px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }
  h1 { font-size: 18px; color: #0f766e; margin: 0; }
  table { width: 100%; border-collapse: collapse; font-size: 12px; margin-top: 12px; }
  th, td { border: 1px solid #cbd5e1; padding: 7px 8px; text-align: $alignStr; }
  th { background: #f1f5f9; font-weight: bold; }
  .footer-sum { margin-top: 16px; padding: 12px; background: #f0fdfa; border: 1px solid #0f766e; font-weight: bold; }
  .signs { margin-top: 40px; display: flex; justify-content: space-around; text-align: center; font-size: 12px; }
  @media print { .no-print { display: none; } }
</style>
</head>
<body onload="window.print()">
  <div class="no-print" style="margin-bottom:14px;">
    <button onclick="window.print()" style="padding:8px 16px; background:#0f766e; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold;">🖨️ Print / Save PDF</button>
  </div>
  <div class="header">
    <div>
      <h1>$repTitle</h1>
      <div style="font-size:12px; color:#475569; margin-top:4px;">Oman Smart ERP | ${_fmtDate(DateTime.now())} | Currency: $_currUnit</div>
    </div>
    <div style="font-size:12px;">${_currentUser?.displayName ?? 'Admin'}</div>
  </div>
  <table>
    <thead><tr>${thList.join('')}</tr></thead>
    <tbody>${trList.join('')}</tbody>
  </table>
  <div class="footer-sum">
    ${_t('جمع کل مبالغ این گزارش:', 'Total Amount:', 'إجمالي المبالغ:')} ${_fmtMoneyWithUnit(sumAmount)}  |  ${_t('جمع سود ناخالص فروش:', 'Total Gross Profit:', 'إجمالي الربح:')} ${_fmtMoneyWithUnit(sumProfit)}
  </div>
  <div class="signs">
    <div>${_t('امضای تهیه‌کننده / انباردار', 'Prepared By', 'توقيع المعد / أمين المستودع')}<br><br>___________________</div>
    <div>${_t('امضای مدیر مالی و حسابرسی', 'Finance & Audit Manager', 'توقيع المدير المالي')}<br><br>___________________</div>
    <div>${_t('امضای مدیریت ارشد / شرکا', 'Executive / Partners Approval', 'توقيع الإدارة العليا / الشركاء')}<br><br>___________________</div>
  </div>
</body>
</html>''';

    try {
      final printFile = File('${Directory.current.path}/Oman_ERP_Printable_Report.html');
      await printFile.writeAsString(htmlDoc, encoding: utf8);
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', printFile.path]);
      }
      _showMsg(_t('✅ نسخه چاپی گزارش آماده شد و پنجره چاپ (Print / PDF) باز گردید.', '✅ Printable report generated & opened.', '✅ تم تجهيز التقرير للطباعة.'));
    } catch (_) {
      Clipboard.setData(ClipboardData(text: _buildCustomDelimitedTable(rows, sep: '\t')));
      _showMsg(_t('✅ گزارش آماده چاپ در حافظه کپی شد.', '✅ Report copied to clipboard.', '✅ تم نسخ التقرير للحافظة.'));
    }
  }

  Widget _buildCustomReportBuilderAndCfoTab(AppUserAccount u) {
    final dynamicRows = _generateDynamicReportRows();

    final double grossSalesRev = _totalSalesRevenueOMR;
    final double totalCogs = _sales.fold(0.0, (s, r) => s + r.totalCogsOMR);
    final double grossProfit = grossSalesRev - totalCogs;
    final double opexExpenses = _totalWorkOpexOMR;
    final double trueNetProfitAfterOpex = grossProfit - opexExpenses;

    final double distributableProfit =
        _deductOpexBeforePartnerSplit ? trueNetProfitAfterOpex : grossProfit;
    final double eachPartnerShare =
        _globalPartnerSplitDivisor > 0 ? distributableProfit / _globalPartnerSplitDivisor : distributableProfit;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text(_t('🛠️ ۱. سیستم گزارش‌ساز پویا (اکسل و چاپ)', '🛠️ 1. Dynamic Report Builder (Excel & Print)', '🛠️ ١. نظام بناء التقارير المرن (إكسل وطباعة)')),
              selected: _reportMainMode == 0,
              onSelected: (_) => setState(() => _reportMainMode = 0),
            ),
            if (u.isSuperAdmin || u.canViewProfitAndPartners)
              ChoiceChip(
                label: Text(_t('🏦 ۲. صورت سود و زیان دوطبقه (P&L) و سهم شرکا', '🏦 2. Two-Tier Income Statement (P&L)', '🏦 ٢. قائمة الدخل والأرباح وحصص الشركاء')),
                selected: _reportMainMode == 1,
                onSelected: (_) => setState(() => _reportMainMode = 1),
              ),
            if (u.isSuperAdmin)
              ChoiceChip(
                label: Text(_t('📜 ۳. دفتر لاگ حسابرسی (Audit Trail)', '📜 3. Audit Trail Log', '📜 ٣. سجل المراجعة والتدقيق')),
                selected: _reportMainMode == 2,
                onSelected: (_) => setState(() => _reportMainMode = 2),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_reportMainMode == 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t(
                      '🛠️ سیستم گزارش‌ساز سفارشی با انعطاف کامل (واحد پول فعال: $_currUnit)',
                      '🛠️ Dynamic Custom Report Builder (Active Currency: $_currUnit)',
                      '🛠️ نظام بناء التقارير المخصص (العملة النشطة: $_currUnit)',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customRepTitleCtrl,
                    decoration: InputDecoration(
                      labelText: _t('عنوان دلخواه بالای گزارش چاپی و اکسل', 'Custom Report Header Title', 'عنوان التقرير المخصص للطباعة والإكسل'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(label: Text(_t('کل دوره', 'All Time', 'كل الفترة')), onPressed: () => _setQuickRepDays(null)),
                      ActionChip(label: Text(_t('امروز', 'Today', 'اليوم')), onPressed: () => _setQuickRepDays(1)),
                      ActionChip(label: Text(_t('۷ روزه', '7 Days', '٧ أيام')), onPressed: () => _setQuickRepDays(7)),
                      ActionChip(label: Text(_t('۱۵ روزه', '15 Days', '١٥ يوماً')), onPressed: () => _setQuickRepDays(15)),
                      ActionChip(label: Text(_t('۳۰ روزه', '30 Days', '٣٠ يوماً')), onPressed: () => _setQuickRepDays(30)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _repFromDateCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: _t('از تاریخ (YYYY-MM-DD)', 'From Date (YYYY-MM-DD)', 'من تاريخ (YYYY-MM-DD)'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _repToDateCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: _t('تا تاریخ (YYYY-MM-DD)', 'To Date (YYYY-MM-DD)', 'إلى تاريخ (YYYY-MM-DD)'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(_t('تنخواه و هزینه‌ها', 'Petty Cash & Expenses', 'العهدة والمصاريف')),
                        selected: _incExpensesInRep,
                        onSelected: (v) => setState(() => _incExpensesInRep = v),
                      ),
                      FilterChip(
                        label: Text(_t('ورود به انبار ۱ و ۲', 'Warehouse Inbounds', 'واردات المستودعات')),
                        selected: _incInboundsInRep,
                        onSelected: (v) => setState(() => _incInboundsInRep = v),
                      ),
                      FilterChip(
                        label: Text(_t('تولید کارمزدی (BOM)', 'Production (BOM)', 'الإنتاج والتصنيع')),
                        selected: _incProductionsInRep,
                        onSelected: (v) => setState(() => _incProductionsInRep = v),
                      ),
                      FilterChip(
                        label: Text(_t('فروش، سفارشات و مرجوعی', 'Sales & Orders', 'المبيعات والطلبات')),
                        selected: _incSalesInRep,
                        onSelected: (v) => setState(() => _incSalesInRep = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _customGroupBy,
                    items: [
                      DropdownMenuItem(value: 'by_item', child: Text(_t('تجمیعی بر اساس نام کالا / شرح هزینه', 'Group by Item / Description', 'تجميع حسب الصنف / الوصف'))),
                      DropdownMenuItem(value: 'by_party', child: Text(_t('تجمیعی بر اساس نام مشتری / طرف حساب', 'Group by Customer / Party', 'تجميع حسب العميل / الجهة'))),
                      DropdownMenuItem(value: 'by_category', child: Text(_t('تجمیعی بر اساس سرفصل / انبار', 'Group by Category / Warehouse', 'تجميع حسب الفئة / المستودع'))),
                      DropdownMenuItem(value: 'by_date', child: Text(_t('تجمیعی بر اساس تاریخ روزانه', 'Group by Date (Daily)', 'تجميع يومي حسب التاريخ'))),
                      DropdownMenuItem(value: 'none', child: Text(_t('گزارش ریز (نمایش تک‌به‌تک اسناد)', 'Detailed (Line by Line)', 'تقرير تفصيلي كامل'))),
                    ],
                    onChanged: (v) => setState(() => _customGroupBy = v!),
                    decoration: InputDecoration(
                      labelText: _t('نحوه گروه‌بندی و تجمیع سطرها', 'Grouping & Aggregation Mode', 'طريقة التجميع'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      FilterChip(label: Text(_t('تاریخ', 'Date', 'التاريخ')), selected: _colDate, onSelected: (v) => setState(() => _colDate = v)),
                      FilterChip(label: Text(_t('نوع سند', 'Type', 'النوع')), selected: _colType, onSelected: (v) => setState(() => _colType = v)),
                      FilterChip(label: Text(_t('شرح/کالا', 'Item', 'الصنف')), selected: _colTitle, onSelected: (v) => setState(() => _colTitle = v)),
                      FilterChip(label: Text(_t('مشتری/موضوع', 'Party', 'العميل')), selected: _colParty, onSelected: (v) => setState(() => _colParty = v)),
                      FilterChip(label: Text(_t('سرفصل/انبار', 'Warehouse', 'المستودع')), selected: _colCategory, onSelected: (v) => setState(() => _colCategory = v)),
                      FilterChip(label: Text(_t('مقدار', 'Qty', 'الكمية')), selected: _colQty, onSelected: (v) => setState(() => _colQty = v)),
                      FilterChip(label: Text(_t('فی واحد', 'Unit Price', 'سعر الوحدة')), selected: _colUnitPrice, onSelected: (v) => setState(() => _colUnitPrice = v)),
                      FilterChip(label: Text(_t('مبلغ کل', 'Total', 'الإجمالي')), selected: _colTotalAmount, onSelected: (v) => setState(() => _colTotalAmount = v)),
                      FilterChip(label: Text(_t('بهای تمام‌شده و سود', 'COGS & Profit', 'التكلفة والربح')), selected: _colCogsAndProfit, onSelected: (v) => setState(() => _colCogsAndProfit = v)),
                      FilterChip(label: Text(_t('وضعیت/کاربر', 'Status', 'الحالة')), selected: _colUserAndStatus, onSelected: (v) => setState(() => _colUserAndStatus = v)),
                    ],
                  ),
                  const Divider(height: 22),
                  if (u.isSuperAdmin || u.canExportFinance)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _copyCustomReportToExcel(dynamicRows),
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: Text(_t('کپی مستقیم جدول برای Excel (Ctrl+V)', 'Copy for Excel (Ctrl+V)', 'نسخ مباشر لبرنامج إكسل (Ctrl+V)')),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0369A1),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _exportCustomReportToCSVFile(dynamicRows),
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(_t('ذخیره فایل اکسل استاندارد (.CSV)', 'Export Excel (.CSV)', 'تصدير ملف إكسل (.CSV)')),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _printOfficialReport(dynamicRows),
                          icon: const Icon(Icons.print, size: 18),
                          label: Text(_t('چاپ رسمی گزارش / خروجی PDF', 'Official Print / PDF', 'طباعة التقرير الرسمي / PDF')),
                        ),
                      ],
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
                  Text(
                    '📊 ${_t('پیش‌نمایش گزارش ساخته‌شده', 'Generated Report Preview', 'معاينة التقرير')} (${dynamicRows.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const Divider(),
                  if (dynamicRows.isEmpty)
                    Text(_t('هیچ داده‌ای با فیلترهای انتخابی یافت نشد.', 'No matching records found.', 'لا توجد بيانات مطابقة.'))
                  else
                    ...dynamicRows.take(50).map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_colType ? "[${r.docType}] " : ""}${_colTitle ? r.titleOrItem : ""}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${_colDate ? "📅 ${_fmtDate(r.date)} | " : ""}'
                                      '${_colParty ? "👤 ${r.partyOrTopic} | " : ""}'
                                      '${_colCategory ? "📂 ${r.categoryOrWh} | " : ""}'
                                      '${_colQty ? "${_fmtQty(r.qty)} ${r.unit}" : ""}',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_colTotalAmount)
                                    Text(
                                      _fmtMoneyWithUnit(r.totalAmountOMR),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  if (_colCogsAndProfit && r.profitOMR != 0)
                                    Text(
                                      '${_t('سود:', 'Profit:', 'الربح:')} ${_fmtMoneyWithUnit(r.profitOMR)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: r.profitOMR >= 0 ? Colors.green[700] : Colors.red[700],
                                      ),
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
        ] else if (_reportMainMode == 1) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      '🏦 صورت سود و زیان جامع استاندارد (دو طبقه با واحد پول $_currUnit)',
                      '🏦 Two-Tier Income Statement (P&L in $_currUnit)',
                      '🏦 قائمة الدخل والأرباح والخسائر (بعملة $_currUnit)',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                  ),
                  const Divider(),
                  Text('۱. ${_t('کل درآمد خالص فروش:', 'Net Sales Revenue:', 'صافي إيرادات المبيعات:')} ${_fmtMoneyWithUnit(grossSalesRev)}'),
                  Text('۲. ${_t('منهای بهای تمام‌شده کالای فروش‌رفته (COGS):', 'Less Cost of Goods Sold (COGS):', 'ناقص تكلفة البضاعة المباعة (COGS):')} (${_fmtMoneyWithUnit(totalCogs)})'),
                  const SizedBox(height: 6),
                  Text(
                    '🔹 ${_t('سود ناخالص فروش کالا (Gross Profit):', 'Gross Profit:', 'مجمل الربح:')} ${_fmtMoneyWithUnit(grossProfit)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1)),
                  ),
                  const Divider(),
                  Text('۳. ${_t('منهای هزینه‌های عملیاتی و جاری تنخواه (OPEX):', 'Less Operating Expenses (OPEX):', 'ناقص المصاريف التشغيلية (OPEX):')} (${_fmtMoneyWithUnit(opexExpenses)})'),
                  const SizedBox(height: 6),
                  Text(
                    '💰 ${_t('سود (یا زیان) خالص نهایی شرکت (True Net Profit):', 'True Net Profit:', 'صافي الربح النهائي:')} ${_fmtMoneyWithUnit(trueNetProfitAfterOpex)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: trueNetProfitAfterOpex >= 0 ? const Color(0xFF15803D) : Colors.red[700],
                    ),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t('کسر هزینه‌های عملیاتی تنخواه (OPEX) پیش از تقسیم سود بین شرکا', 'Deduct OPEX before partner profit split', 'خصم المصاريف التشغيلية قبل تقسيم الأرباح')),
                    value: _deductOpexBeforePartnerSplit,
                    onChanged: (v) => setState(() => _deductOpexBeforePartnerSplit = v ?? true),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4].map((d) => ChoiceChip(
                          label: Text(d == 1 ? '100% (÷1)' : '÷ $d'),
                          selected: _globalPartnerSplitDivisor == d,
                          onSelected: (_) => setState(() => _globalPartnerSplitDivisor = d),
                        )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🤝 ${_t('سود قابل تقسیم:', 'Distributable Profit:', 'الربح القابل للتوزيع:')} ${_fmtMoneyWithUnit(distributableProfit)}\n'
                      '👤 ${_t('سهم خالص هر شریک', 'Each Partner Share', 'حصة كل شريك')} (÷$_globalPartnerSplitDivisor): ${_fmtMoneyWithUnit(eachPartnerShare)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('📜 دفتر لاگ حسابرسی و ردیابی عملیات کاربران (Audit Trail):', '📜 Immutable Audit Trail Log:', '📜 سجل التدقيق والمراجعة:'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const Divider(),
                  if (_auditLogs.isEmpty)
                    Text(_t('هنوز لاگی ثبت نشده است.', 'No audit logs yet.', 'لا توجد سجلات بعد.'))
                  else
                    ..._auditLogs.take(40).map((log) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('[${log.section}] ${log.description}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('👤 ${log.username} | 📅 ${_fmtDate(log.timestamp)}'),
                          trailing: Text(_fmtMoneyWithUnit(log.amountOMR)),
                        )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showImportRestoreJsonDialog() {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _activeDirection,
        child: AlertDialog(
          title: Text(_t('📥 بازیابی دیتابیس از متن یا فایل پشتیبان (Restore JSON)', '📥 Restore Database from JSON Backup', '📥 استعادة قاعدة البيانات من ملف JSON')),
          content: TextField(
            controller: jsonCtrl,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: _t('محتوای فایل پشتیبان (JSON) را اینجا Paste کنید *', 'Paste Backup JSON Content Here *', 'الصق محتوى النسخة الاحتياطية JSON هنا *'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              onPressed: () async {
                final raw = jsonCtrl.text.trim();
                if (raw.isEmpty) return;
                try {
                  final decoded = jsonDecode(raw);
                  if (decoded is Map) {
                    await _createBackupSnapshot(triggerType: 'pre_restore', customNote: 'نسخه ایمنی پیش از بازیابی دستی JSON', silent: true);
                    _applyJsonState(Map<String, dynamic>.from(decoded), includeBackups: false);
                    await _saveLocalData();
                    if (_autoSyncOnEveryChange) await _pushToCloud();
                    Navigator.pop(ctx);
                    _showMsg(_t('✅ بازیابی کامل دیتابیس با موفقیت انجام شد.', '✅ Full database restore completed.', '✅ تمت استعادة قاعدة البيانات بالكامل.'));
                  }
                } catch (_) {
                  _showMsg(_t('❌ متن واردشده فرمت JSON معتبر ندارد.', '❌ Invalid JSON format.', '❌ صيغة JSON غير صالحة.'));
                }
              },
              child: Text(_t('شروع بازیابی (Restore)', 'Restore Now', 'استعادة الآن')),
            ),
          ],
        ),
      ),
    );
  }

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
        builder: (ctx, setModalState) => Directionality(
          textDirection: _activeDirection,
          child: AlertDialog(
            title: Text(existing == null
                ? _t('➕ تعریف کاربر جدید و تعیین سطح دسترسی', '➕ Add New User & Permissions', '➕ إضافة مستخدم جديد وتحديد الصلاحيات')
                : '✏️ ${existing.displayName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: _t('نام شخص / واحد', 'Display Name', 'الاسم'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roleCtrl,
                    decoration: InputDecoration(labelText: _t('سمت / عنوان دسترسی', 'Role Title', 'المسمى الوظيفي'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: userCtrl,
                    decoration: InputDecoration(labelText: _t('نام کاربری ورود (Username) *', 'Username *', 'اسم المستخدم *'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passCtrl,
                    decoration: InputDecoration(labelText: _t('رمز عبور ورود (Password) *', 'Password *', 'كلمة المرور *'), border: const OutlineInputBorder()),
                  ),
                  const Divider(height: 20),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('مشاهده گزارش‌ها', 'View Reports', 'عرض التقارير')),
                    value: pViewReports,
                    onChanged: (v) => setModalState(() => pViewReports = v ?? true),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('ثبت تنخواه و هزینه‌های روزانه', 'Manage Petty Cash', 'إدارة العهدة والمصاريف')),
                    value: pPetty,
                    onChanged: (v) => setModalState(() => pPetty = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('مدیریت انبار ۱ و ۲ و انبارگردانی', 'Manage Warehouses', 'إدارة المستودعات والجرد')),
                    value: pWh,
                    onChanged: (v) => setModalState(() => pWh = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('ثبت تولید کارمزدی و بهای تمام‌شده', 'Manage Production (BOM)', 'إدارة الإنتاج والتكلفة')),
                    value: pProd,
                    onChanged: (v) => setModalState(() => pProd = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('ثبت سفارش فروش، برگه خروج و تسویه مشتریان', 'Manage Orders, Sales & Exit Slips', 'إدارة المبيعات وسندات الإخراج')),
                    value: pSales,
                    onChanged: (v) => setModalState(() => pSales = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('مشاهده صورت سود و زیان و سهم شرکا', 'View P&L & Partner Shares', 'عرض الأرباح وحصص الشركاء')),
                    value: pProfit,
                    onChanged: (v) => setModalState(() => pProfit = v ?? false),
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: Text(_t('انتقال به اکسل (Excel) و چاپ گزارشات', 'Export Excel & Print', 'تصدير إكسل والطباعة')),
                    value: pExport,
                    onChanged: (v) => setModalState(() => pExport = v ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final uName = userCtrl.text.trim();
                  final uPass = passCtrl.text.trim();
                  if (uName.isEmpty || uPass.isEmpty) return;
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
                  if (_autoSyncOnEveryChange) _pushToCloud();
                  Navigator.pop(ctx);
                  _showMsg(_t('✅ دسترسی‌های کاربر ذخیره و به سرور ارسال شد.', '✅ User permissions saved & synced.', '✅ تم حفظ صلاحيات المستخدم ومزامنتها.'));
                },
                child: Text(_t('ذخیره کاربر', 'Save User', 'حفظ المستخدم')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminUsersAndPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: Text(_t('🔐 ۱. مدیریت کاربران و سطوح دسترسی', '🔐 1. Users & Access Control', '🔐 ١. إدارة المستخدمين والصلاحيات')),
              selected: _adminSubTab == 0,
              onSelected: (_) => setState(() => _adminSubTab = 0),
            ),
            ChoiceChip(
              label: Text(_t('🌐 ۲. تنظیمات دائمی آدرس دیتابیس، ارز و زبان', '🌐 2. Database URL, Currency & Language Settings', '🌐 ٢. إعدادات قاعدة البيانات والعملة واللغة')),
              selected: _adminSubTab == 1,
              onSelected: (_) => setState(() => _adminSubTab = 1),
            ),
            ChoiceChip(
              label: Text('${_t('💾 ۳. سیستم پشتیبان‌گیری زمان‌بندی‌شده و بازیابی', '💾 3. Scheduled Backup & Restore', '💾 ٣. النسخ الاحتياطي المجدول والاستعادة')} (${_backups.length})'),
              selected: _adminSubTab == 2,
              onSelected: (_) => setState(() => _adminSubTab = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_adminSubTab == 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _t(
                            '🔐 مدیریت کاربران، رمزهای ورود و تعیین سطح دسترسی هر شخص (ویژه نرم‌افزار مادر ادمین)',
                            '🔐 User Management & Role-Based Access Control (Master Admin Panel)',
                            '🔐 إدارة المستخدمين وكلمات المرور والصلاحيات (لوحة المدير العام)',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showAddOrEditUserModal(),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(_t('+ تعریف کاربر جدید', '+ Add New User', '+ إضافة مستخدم جديد')),
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
                                    'Username: ${acc.username}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF0369A1)),
                                  onPressed: () => _showAddOrEditUserModal(existing: acc),
                                ),
                                if (!acc.isSuperAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() => _users.removeWhere((u) => u.id == acc.id));
                                      _saveLocalData();
                                      if (_autoSyncOnEveryChange) _pushToCloud();
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
        ] else if (_adminSubTab == 1) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t(
                      '🌐 تنظیمات دائمی آدرس دیتابیس سرور مرکزی (قابل ویرایش در هر زمان توسط ادمین)',
                      '🌐 Permanent Central Database Server Configuration (Editable Anytime)',
                      '🌐 الإعدادات الدائمة لعنوان خادم قاعدة البيانات المركزية',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _loginCloudUrlCtrl,
                    decoration: InputDecoration(
                      labelText: _t('آدرس دیتابیس / سرور وب‌سایت (Database Server Endpoint URL)', 'Database Server Endpoint URL', 'عنوان خادم قاعدة البيانات'),
                      hintText: 'https://your-domain.com/api/oman_erp.json',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _initialDbKeyCtrl,
                    decoration: InputDecoration(
                      labelText: _t('کلید امنیتی / توکن API دیتابیس (اختیاری)', 'Database API Token / Secret Key', 'مفتاح الأمان لقاعدة البيانات'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t(
                      'آپلود و همگام‌سازی خودکار با سرور پس از هر تغییر در اطلاعات (Auto-Sync)',
                      'Auto-sync changes to database server immediately',
                      'مزامنة تلقائية مع الخادم عند كل تغيير',
                    )),
                    value: _autoSyncOnEveryChange,
                    onChanged: (v) => setState(() => _autoSyncOnEveryChange = v ?? true),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() {
                            _cloudSyncUrl = _loginCloudUrlCtrl.text.trim();
                            _initialDbUrlCtrl.text = _cloudSyncUrl;
                            _dbApiKey = _initialDbKeyCtrl.text.trim();
                            _isDbAddressConfigured = true;
                          });
                          _addAuditLog('تنظیمات دیتابیس', 'ویرایش آدرس دیتابیس سرور به $_cloudSyncUrl', 0);
                          _saveLocalData();
                          _pushToCloud();
                          _showMsg(_t('✅ آدرس جدید دیتابیس ذخیره شد و اطلاعات به سرور آپلود گردید.', '✅ Database URL updated & synced.', '✅ تم حفظ عنوان قاعدة البيانات الجديد.'));
                        },
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: Text(_t('ذخیره آدرس دیتابیس و آپلود اطلاعات به سرور', 'Save DB URL & Push to Server', 'حفظ العنوان ورفع البيانات للخادم')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pullFromCloud(overrideUrl: _loginCloudUrlCtrl.text.trim()),
                        icon: const Icon(Icons.cloud_download, size: 18),
                        label: Text(_t('تست اتصال و دریافت اطلاعات از سرور', 'Test Connection & Pull from Server', 'اختبار الاتصال وجلب البيانات من الخادم')),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Text(
                    _t('💱 تنظیمات واحد پول («ریال» / «دلار») و ضریب تبدیل ارز + زبان سیستم:', '💱 Currency (Rial / USD), Exchange Rate & Language Settings:', '💱 إعدادات العملة (ريال / دولار) وسعر الصرف واللغة:'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  _buildTopLangAndCurrencyBar(),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t(
                      '💾 سیستم پشتیبان‌گیری خودکار/دستی دیتابیس و بازیابی اطلاعات (Backup & Restore)',
                      '💾 Automated Scheduled & Manual Database Backup & Restore System',
                      '💾 نظام النسخ الاحتياطي التلقائي/اليدوي واستعادة قاعدة البيانات',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_t('فعال‌سازی پشتیبان‌گیری خودکار زمان‌بندی‌شده (Scheduled Auto-Backup)', 'Enable Scheduled Automatic Backup', 'تفعيل النسخ الاحتياطي التلقائي المجدول')),
                    value: _autoBackupEnabled,
                    onChanged: (v) {
                      setState(() => _autoBackupEnabled = v ?? true);
                      _restartAutoBackupTimer();
                      _saveLocalData();
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(_t('زمان‌بندی دوره بک‌آپ خودکار:', 'Auto-Backup Schedule Interval:', 'فترة جدولة النسخ الاحتياطي التلقائي:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(_t('هر ۱۵ دقیقه', 'Every 15 Min', 'كل ١٥ دقيقة')),
                        selected: _autoBackupIntervalMinutes == 15,
                        onSelected: (_) {
                          setState(() => _autoBackupIntervalMinutes = 15);
                          _restartAutoBackupTimer();
                          _saveLocalData();
                        },
                      ),
                      ChoiceChip(
                        label: Text(_t('هر ۱ ساعت', 'Every 1 Hour', 'كل ساعة')),
                        selected: _autoBackupIntervalMinutes == 60,
                        onSelected: (_) {
                          setState(() => _autoBackupIntervalMinutes = 60);
                          _restartAutoBackupTimer();
                          _saveLocalData();
                        },
                      ),
                      ChoiceChip(
                        label: Text(_t('هر ۶ ساعت', 'Every 6 Hours', 'كل ٦ ساعات')),
                        selected: _autoBackupIntervalMinutes == 360,
                        onSelected: (_) {
                          setState(() => _autoBackupIntervalMinutes = 360);
                          _restartAutoBackupTimer();
                          _saveLocalData();
                        },
                      ),
                      ChoiceChip(
                        label: Text(_t('روزانه (۲۴ ساعت)', 'Daily (24h)', 'يومياً (٢٤ ساعة)')),
                        selected: _autoBackupIntervalMinutes == 1440,
                        onSelected: (_) {
                          setState(() => _autoBackupIntervalMinutes = 1440);
                          _restartAutoBackupTimer();
                          _saveLocalData();
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                        onPressed: () => _createBackupSnapshot(
                          triggerType: 'manual',
                          customNote: 'نسخه پشتیبان دستی ثبت‌شده توسط ${_currentUser?.displayName ?? "ادمین"}',
                        ),
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(_t('ایجاد نسخه پشتیبان دستی فوری (Backup Now)', 'Create Instant Manual Backup', 'إنشاء نسخة احتياطية فورية الآن')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showImportRestoreJsonDialog,
                        icon: const Icon(Icons.restore, size: 18),
                        label: Text(_t('بازیابی از فایل/متن پشتیبان خارجی (Import & Restore)', 'Restore from External Backup JSON', 'استعادة من ملف نسخ احتياطي خارجي')),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    '🗂️ ${_t('تاریخچه نسخه‌های پشتیبان ذخیره‌شده و بازیابی یک‌کلیکی', 'Saved Backup Snapshots & One-Click Restore', 'سجل النسخ الاحتياطية المحفوظة والاستعادة الفورية')} (${_backups.length}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  if (_backups.isEmpty)
                    Text(_t('هنوز نسخه پشتیبانی ثبت نشده است.', 'No backup snapshots created yet.', 'لا توجد نسخ احتياطية محفوظة بعد.'))
                  else
                    ..._backups.map((b) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '💾 ${b.id} (${b.triggerType == "auto_scheduled" ? _t("خودکار زمان‌بندی‌شده", "Scheduled Auto", "تلقائي مجدول") : _t("دستی", "Manual", "يدوي")})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(_fmtDate(b.createdAt), style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${b.summaryText} | ${_t('تعداد کل رکوردها:', 'Total Records:', 'إجمالي السجلات:')} ${b.totalRecordsCount}',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0369A1),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _restoreFromSnapshot(b),
                                    icon: const Icon(Icons.restore, size: 16),
                                    label: Text(_t('♻️ بازیابی به این نسخه (Restore)', '♻️ Restore This Snapshot', '♻️ استعادة هذه النسخة')),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                    onPressed: () => _exportBackupToFileOrClipboard(b),
                                    icon: const Icon(Icons.download, size: 16),
                                    label: Text(_t('دانلود / کپی فایل بک‌آپ', 'Export / Copy JSON', 'تصدير / نسخ الملف')),
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
      ],
    );
  }
}