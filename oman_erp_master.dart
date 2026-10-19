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

// ============================================================================
// هویت رسمی شرکت صنایع غذایی بین‌المللی ارواد (Arwad International Food Industries SPC)
// شماره ثبت تجاری عمان (CR No): 1658937
// نام عربی رسمی: أرواد العالمية للصناعات الغذائية
// طراح و معمار نرم‌افزار: رامیار عزیزی (Ramyar Azizi)
// ============================================================================
const String kCompanyCrNo = '1658937';
const String kCompanyTitleFa = 'شرکت صنایع غذایی بین‌المللی ارواد (Arwad International Food Industries SPC)';
const String kCompanyTitleEn = 'Arwad International Food Industries SPC';
const String kCompanyTitleAr = 'أرواد العالمية للصناعات الغذائية';
const String kDesignerNameFa = 'طراح و معمار نرم‌افزار: رامیار عزیزی';
const String kDesignerNameEn = 'Software Designer & Architect: Ramyar Azizi';
const String kDesignerNameAr = 'مصمم ومهندس البرمجيات: راميار عزيزي';
const String kArwadLogoBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAQQAAADHBAMAAAANLTCXAAAAMFBMVEX///////7+//7//v/+/v/+/v7+/v39/v79/f3v8PJ3hpQwRlsvRFouRFotQ1kkO1IMtyRGAAA2DElEQVR42l19TXAjR3ZmNsF0F3ouHHs6Vrsnhtpca25wYxGWdy+ULcZQPiVRrGFRJ29sKGKOCm9wt+VTSepUF7sv8HoYQxDrJsNhxfBnR/BRZOHnPAbAPtv4mXOLBPpMQMPe772XVaDMaXWDQKHq5fv93k/mqMDoIAhMQH/zC6VW+N9AG/qL/hh6xT9b+M3n65TSQTHAn2W6divwi/QmfZGu1UEpwJ/0awv4jq/1Cr5bClbCwPgh3cPgHjpQ/LAgzq42yr2ygVBHH2uhTvtBAf/zS/QJ/hTpfZ+/WnTXyTdACp5VDFRRBTv8VmmHryzhL6bT4j6Gr8KaQ765Y0L642jDFxas444NiOiggBsZIcHyoxzluI2sCdeUTVH4gP90ScjCE/1Abz3CqxI/QFaoA3mSsA6c54uLmrikYxaOKqWMYipXHhWJ3Uqo4rto+mP4HY3XBaKBxLXCS3RPk8/wjZyTD12vSyxg5SRgA/dCZB3KwkDFFl5afJ1kH5gyr0UHc8Kt0ibUyqcnpUI0dEWRpcKKQ3+XeH2FhfTb8jjohsm4QFSkq3FKkb3SiiQmX8PDwK47y8NPTFpC68GqSkG5xF/N8UWPCpY/o+fq8N0CaHELcPpVYoYYJwSV3rwkFBgSJD1Vm1QzQxgHlqrjFUXKMadkARpAmkDWpApMkmYmsyowC8J06SUxuNC9Irka1gl+PLFBO3UxW8G7PquXYS1hPmh5qIlOvEwZ6N/HbCWijfRqi7hcdLf1lVtSylY8wQ/9YEU788lsjnTGBI9JLVYCj7WY7xeKrWcmF5g1Lz+LPw1IWQyzTxthtSNRrlth7QvgDnYCS3e12tkw3+7xAnHoMUlZx0HmAlIprGSCTp/r5C/WpMLa26NoDczht5XxMxuZXwUKfP9xKbsLFGVFm60tkF0u4e0FXSID17SAMP0uG4sW78HugCiEAEQYGfk6uBfVW+dbf2CN8wxaldiX2oyCx9r3g0c+L80PApVeaPgJgX4fL0Jyck7pROAm2PFLJvSJQrxTYsmojDvuFahWQZi/7Uw9MWQFTuhySRdZXL4WZ152YuSvrOA9/jpcjs+ONLBabLJIiuJMmTldYuUoiuMoC905XGyV01gmeDMIn8867crTO/JZlsWHW8axs5RK3YdfVB4rOqzA8cka0W2/5O4b3HHPxhnTQrpuk8NtFbPL8ANDsxnVm6NX55a9Ju5GGmEWxG4sK0+utFwgzc+VA1/uSCQ8Kmif45gSLXLexLlpVsEyNHiH9VGRcRvWc6O3fGe59ADoz+b6dqM5uZp69+ih7M7pOhsyl5zADROSC0r+neUp7RdNqcgxSCm53IhRZqoM/6Z8Mgdl4IXmrjKMjXHqCmuFHMaT8ahiP3H8M6mpiD2qNBAFds5ZKJ8Pz5XzU8vWjgNEClklop7Q8eUKf1pWpI6smSkEkK+AgTnIYTjptY+fOlegRF2JSPG0hXkI8PXcEFz0IWcSlMDokBepsvAQZM46yBAKBOOXVvywzOrqPI8JP2slnWTQn3paFEY7n+sYwst8nJMAVfDFDPEJ1Atigc802hf9cODCClcWmAS4kgLjAbIVFpVfuoMX5Evhg1mDSLja39kQ1iudhteScyb0qlSWIOlU3DxmNfPnoSVVU0ExCMPBjmU7yaWqg7dDu4W/cwW2BWU8xgrRYaPbTQa99tHnGxJNfoh36JvGrjhQlLEa+l5KfZsxBXIgTIayco2G+qZfCYPUjsKyzxIuafddQ855t5V0O43BsPPaCx66tdh06Uy6FkRHLLShkQAnoXmnJLBTwi6zVZENBB6sGWKiSFsszm1IixX8z2UlKg+XarUiOSTdxnCYzOIfL3KUN4yqWA1D0jJRS4eITKaqpA+6IOFqh98CNWSdipEX4eGQg/tyKdjSKWL53xTi2JlZp2xhdJgkSW8IEtpHETktdtEMqyjOL4hS8+XlYskFKeNZApscznzhl19m6owSKKAprPqINaUUawnn8Xtq2vwCF9/fbSdJs9vt9ZPm+VawypHOCZwBC38fj4OX84vaZj4gEOnwo4IciCs51cH/YmscGHSxw+QE7BijJSo4ObAP8B7Mup0hUZAkU++dLAoS/4Ki7xAXmUVBB3d0n4gprzjopIsSBwwjIWJDyB6FYJz2Sz/EhTaYmzCRGkS1pNFpdgcDkNCu2NQfcQjRwR3PV9b6jkWCBCi3X3gUFI1bvjFhJPqixS8SyibsUJZQ60zJmBQqCNoLwt1v8OzmsIu/kva5Xb3HEqU4BnId9DAZBHVJT8phWmvqQhyLIuXSAorRfnFZZ+hwzghz5wuQQ37WScCHQXPQHJKDXGVwq7KAUnLuxjgY7pdcFNLir+jOwCUUBxgRKuUyGKVTR8afZHQahlXMCn5Hrdp6o5s08XgiYVR5uqkZc4QO4iktj9Sk2kXmcpTy1AYpzHJxX0Kmw0NYhpYVzBEiq4shHivmLf0bWwtdgHNMBs1et9f++gtOM1QwN6MVJakfvuw7lE0k4q0nfsragk4N0sVHZnv5EVHgi/3EohtKzAHpkghYeXEMzwTnmDR6vU6XJLGWPjsOxBsYogFKdd+mIJw0IXTwI7C5wE+XSMrhohg5JwkQyiUGkldpYRyHC3JkQe4duxrXG1DIBJIYJghViLKW4zU5ThIAo40UxeNxy0GGeDi3JudVSrGwTdWeMbaD634hZN0xoYtWktQavo1avqfsIelj0oMckiYcJK9DpWkMRwLfZZZYeDE1WM6YOfCW5oCfQrHD1rHoYAafzN2yh4tcTOr28ZMYkoA6gA78SW480hZ6vpqHTJ36PW1T3XKu75PCX6Z3daE/JUHci7mTr9CXhRCVgkOKkg+mXrxLRtkhaQyS/jRecR7JIHM0krcr5ehn+dxJkG3pfwQrbHouB3F5vs3gUsGVHrLk24VZRBiG3yY6nO1HiFPEA9IH2ARClXEws5S5alcz4sSLbwLVB7zF4zf/lEIx4NwyX0BeieO7Yft35BqpmRi5iVZ8iRAZxnU8Mvx41hESmo1G6zxel5xnQ1IY3IViIqdqIUNORXkIhVrkQFDHAlte8H4aS1SWM3K5xARZmHdBQeuUEUbHpAavIYlbJqBL/8EssbRnT+L0x5rQmpR/pOX0Jn/+LI4ZO80fwYxSeg67JBEhIB86U7GSO8D3W6bU1vrAKXFUT0gdmA4KVTE08s6PFI3SxD76wUdBTnFdg032U5ez3AH6qaVIFss8cPUNcWY/RjZ7+eooimtXDQCnPsXrYfs4DvPVOz/pDS3FP/XvPgNSKZVWivTsLT+zDA4AxqZZCYmNFJL0SOKvEXsz+p38rNe9PA/j/FWjAy6AD80+haqPkuabCf+8uZ16bJ8xcRg8Dmu/Hw9H+GQ0bk5uPFF5MAcOIhfoLTZKbebwP5wXG+UdI5UBZ8JYPeOUZZJETwTRH1ztG/xO8KE56PUGbyrRahoYsQ6kPYBXQ5HZUbRD4aFA2bXUv3x2yOYHae2dusYd38RWmmMdaLYrkYUkOhSrcHOYZRzXZvx6MuwPXx3Hzu1QOc7b7jMJQ2JZfz+SEmmY4TgtYMGquVs3WZ5NBR7xu5J4Koj1qjccjdvHzyhUJUPiQw8e4ub9ME8OczgZTyZjpLvWOL6ZADAPzwfYTXpjiCyr4wjg12kZxQEufpwrOjsqI1dNoqs2g/j5bDgcdXAn+Ac8sYuV9XrDzjTeAn+ao+F4CJlfQzApL4HMXib95rAJyD+Z/O7YUrWa6mhUCqHqnApcSUzr4Adebe7orSTL9PJhgOc0sKT+1Z7FnbtdEv8Q0ockACK6w8mIHjSBxHUasyjtoaCKr43Gv6tYqZD7Amc4ESyVlHJAz2TFpjTi6TtFNCxoKdxuklCHQzwD/B0Me42kM8Q7rfMnkMxwNJwMiATovSZjgLN4hyWWDIfNPkQB7gXpqkUdAOsKXEuyqfbfrblK4A+NW5BZ3CCxXuJWY0THeLfVHXY73UZnOCQHqeN2A2Y3mYDCq2ksiFwt/SnLodEbJs0OKI3Dcimru0Lm7+IRxYLirNJok6X5VLhPg3msTVqW/zFls1gpGNqZkRk2et1BpzfsjXq9VgWhq3E5BgkT5tLnzsEsxTBJsCDpNTojyMtkhTNyQyvvUubgSzZlUsis5u4RAtqi7MPhWB3uti/BAjxiTKHqxazTG/QSEky3/eunHkuC9HGM5VqXr7//YNYHC5IuCEFYFwydZrU2ba5I8dIVTI1zF3e0EpASWhUGmxDriMxrMrpmBznr9ob9LpFAxY5wu9WDJEDDmMzSQRT4skEfLoFIR3zTgWunCCzlAqg/b2pkQIfB5dw4rJRjYaAvG5ekciJ8hCrg6CFISIYjQpDwguSFJ8MxVKISyTrxJoB2H7zqwzV+BcTg6yxSUjlhhUnQnF4LatMcyZT0DGA9QCNBUXOJdGu33sIjBkOyAYqOcJC94aBFzO+2j+h30oRBb0L+MuLEAB4L7hI//WEnIaCLhFYXBAKRt4V95MokGER0zjlLxB0u/3NfzKT1I3Kiob2fb13SM0agYoREjoTfbUD8oKvbf+3hcayMEMfw6sZb4VT1BUjoD6gQ0L2eemW1ZYItB5wpAgug5jAVWu2rUlo1C7JkWhQUBk55BBxTd0TaBjdM0gaW7za7UI8BLGMaKgRy6MEAopr0Z/vBByIHKEqP/NKk/etI+3/mzxNKNgsk2H6qC/6KltqeBayRkkJYpKul1KM2wvBvr7qXk+HkGmu9Tv7ORofdTq/ZG4DLQJAVa19eQxGGvTE7yKd2EzbUQuQakCgmg2YlosJc0dzpqZGBGF/dccpK3UnmuJlQzvB1+PSd/GR0OSbHAFnAxmEhnUafmDzpkdsBqOtCDIINzmOrqBJBDhzaA8YgRJkcZbX+I1KFnGKOF9/lyq6Z9ygJ6uDKMsmfSCk49dU61IrUm9RhDNZ3bjxy/w3IeTwaNBsdwvatRo9sAmyAoEoP/egQoRwOgZzJq3PCjcVHxaJflGJLFKgS948IwFLlWqxAiWflDLmw5ftbnDFTfLcVMvLGhEnoDq5n+19BOToIUlCGTj+5+pU4yAl4hGt+V3kWkxwmZLRw6QQyjCKZFoNiyPVvqq2zrxKYoLLSqeQQd8C0pqw9DPMAzvlZU0gg7YIknsNBjiZsc00JXfTZhEhoHz99Bsk08TEc02jAUIHqbCR98QBpdn8neYVdmpiLIvLpQtYPwn/xwTTeIJ0nEuiv0W9DL/89IAuR0Oh3+jeet307uYY2kG3ikb59eQUWwSM0R9e9c1dkSovgfF/KxBlxwyg5pQhTRtjUIFMIpaAHAM72/woP3DM04QcKjs1BH56HsH1jMGHoRGYZEcUgAc6xMaKci+6US+vJUi0gXghqUi7TDvWdfp0qSCFC3NzbyXkIG4D3HeEPVtuuADFeARwjLvTZ/9LvXWIQBW38mp+NiGDiA5IPp/PKf8812SkbJmsoKV/fTR/ugtdSseCn1YvnsyvWeVIGPBPPoOj/YAbGg9lkmq3XkMxsxB9DIzvnYW02gvNswotT/q24nMGP2KGSF7dlEKrgkqkaJVlkGiul3QNpwIC4A2sM2eOrI8A1IaE3vqRw+IdwkEAMZJSjEX4vRPVLAm+krldTxXKgXxnapdVR8gyu/EA4Eo8HYPG5OhW61c+zf878mXL9Was1ecNxgcMEQvZgfLVn7EuA2DGUDeKYwOyeHl6PB8NrhjXt6tUI9IzGgwT07lkTZM0+tkgkE8tU1iFh2EKqeBwYvKyvrtOqAjUg2N38bLcNCroACogEFB3hEK+H4iGHrWNykLCQCelH79XpjPVkQsCRAEQ8bwpzH93Pxh4Mx2w/DP0gHYJIuxoUysht/RxQASQkladQ8tFwMJgMIIr+a1YOZnwXUncOknz4ZDIYXb8hyoiGyaB9HHF0lt4FBSapE7viNUXtnM06xUICI3fwaIHRZnm33Zpcd9vH1nsxu+4NSM0vBw5Bdgf9gZjp1f7ncJATQjWkkQnjSOJPt1khhFxmd7BcDqQyB+WL6JG5dGCAujIlFr0jzgSZe4IKjIfXPbDTy181BwNKjobUlIlAEqATaQKeifDoPZ+RQZBJDAf0F+NdcY0uPWXpLsuKi+Zdjg0BtWO1X5TZk3kqltWSwy9qXQqASJPY+4xI3MAAQJAEizqXcEZkBGOEro+uuz34x96IvPiQ3AI8ZPscwHWBXZ820ovjultYLj7S5BflaVuFwhOqOnD+yIWO0CodaqnuNCdjdjdP2fuQxwMjIHzCMQgTlM0CSExjSKY1IJ6MGWnTK/Za0ScpJGAWG3YJPiKG5jBlHoOqBbVSsloKwABJ1tWTQ6qZrsMe6DEDOBhqRlyPe4Ct46E4yH6XmMBgCY/6GSPIHpwXY0ZyEeTLKSWSfjItMa2qh8ZwV78IHKHLnM/SDE4ubb2mRTfzcAe3hU8edTqz2MIbDeiB4MS49S3jFI4btOTLc6pJIlT2RlBBUhcmgkOUjGGYZSmo8NyTXZBgqRi7OYACIlgx0naC4boR9cgBUyD8V0dfUUNk0AXjoZSQxAaENBLVH5HDjAlRkhWQwlIuORxdUohyLs/4d0KB9HGtcwIlsgR/JUjboiZzkVTduYJ2kbVTCgNJIKunyDAYJFd7EbmMISkf/YGD5N8ZQ3T6UBik1OCdPFQZVzrI0X1XKKOx8y6mLVLKbXiMihrD5BWYOSANSJyWCX28xrI1wTPKp7ucPLLPRjC65OAEoELRFCT0Bt1+Y9gAJQ1gvKVQqoYLVFJgZTeqyH1MapeCA9zZLvlBcUfq7dIjyfHghOYQRQZObu66VQFwThAhOp1+Mxni7vd3W63rIfvhIWFURpCQEsmK0NSwATpdbsxAzYRc8icvwNoP1LRVSlmxcieTpHhBeopvULIo8ZlRAFU/u/0eN+iS2f5fwgyvxf7gGa72n8FMh0RCk/MuyAHehHpW2rJrKt0pa61Ynv4AMOG+YZDOYGUZPhEGir3/SnIgkyAkHi6H2xOuXHHhAiuEnBq9MSfVhCgjIMpJd8zlJYauHSpsUDJrnY0VQI1/p6RD1UnD6J5gZWk5TXNUSHCG6unRYetyzNEYd/xXzxCWT6gP0ARea56H6/mZ1LlGVFokkHs7YZPpMlYAkLWhTSc54nIQpjOUj+jBUJBYuXQleFQuEVDLJrhCbg1SRgR/NyQmcHy299ZrVwk1AkBCR1LspjhEUpZpbKkyCHMZNIYMtS+RAQelBUoaTXp35JUryCNWJHtVZdEB5DglGdsRp2DdKBw0HPAA2oZVInnA7dbzV9IIAAkNOEhb6w9AH4iQUleAdAMsaLBXGsJXPGSGUyWQgzVx3M2N+ewUuY1G3qiYNpYFK4SuXYnMEXCVLA5GeUNFCi68dTrJMBkkHUQghlJjDpeUyVHlq3uNXJZKG43uq3MrFQXNFi5JrUrHA0p+Wnc0aUqNf6MgC6pcJwFUGFNsxN/chwo+tLVrAsVQ+6TDlS5KqYecSxK0QlSDjQx6vQZxgUxy3m0yMleFZeucCXI0vpkrSXnD6C+pvSSjiJar8p6wTzIksrlx92qfGw1UWWiSHHrJYEgO8hAJ90CsdvKqEkcvx1RU6A05msKocgjOvqtWaAmVnk3H4FJ3YTksmLTf7NpUEBIETRWksVshl/ICmh5IYPN4yKT9dYRI2iMYM2JOHZNk+r1Rj2qUo845luIvix/2WLm4U1d2kVCXYqlDGqXDO9OvkkAxJZzDkcmP2bzw8UawRjMUjR60dNAkBxlTik1lMCo8XokP7xKL+kOXRcHZrwT8jNCXuWG/5HMn91FWV2HiQtLBdGRFRr+AirqXNEVF0risxG6OAw4SQYD61v3+d9yk6UJU12QS45m0BkDhACo5o3r0n8ksCayszKPHpRSpKvpnR/FgjZtaUT+YWcSX4tpsMOhRyYCSE4+np4GitpMmgmW/ScImn/0cUIqsRszSxh/PRqABPEqoBwKQwMHR0nPKigf+/Efcr9X+gs8F4Md6PiKmQ6NSF6K4qtHrXnI179V5/ImbA6YaUhfpQWM0TCixy1/hknGPKwuE7f+82eiCBOogWkEojMLus6PegjSCxyU/fWSJIqVkFfMirJHuv3kIwAzLumRzQ7b01HIdZvHee7UZAjbjlgQxYCESs+TMv88OskkVT2DXvafSGOe+M6UqpTAoPWLXpEuIkitMwnKplI1CZ+PBohTgcEK1pQnLYV1o/Mr8IfJX5JESiUZvKl/Y2qTbHUjdger0Ye2qQ419yG6JS+kW3OZuWESG+LhUflzcEkexYgpKRqqkb6jnkwtsIeQHu+J0xsl51sFbLFMcoL5Ac0xmaMkhdsUvQCPOKcVuDEe9LnynuNyymysg38SP830xO02j2CW/qFMYKbDRTXlbdf+zZjIYNCknGWNxX4U84ATBbtpaIjQMh5LItbkmySRg6UaqwQMgnMCW5vUCXWRyHnFqXXL5HDTl8bJSTmVkmoAzXMB3yqKQGA2IDUOYF1C/lTky+w7MsoO8EcGIml5wiEmPa0zkGt5UIvuSKCAfgcS9WJpPuXCWQLN+FKxjoQzqSGM8PGfLs208FEId7g1AhQTInFztiFot5MrdKNta3II19Idjaf3FnHqz3ZCPPo7ee/D9ZNKBsSg4n9zf+CvzTh/N5Reda+RWeVnJ1I+mXRihm8Z23fu13XaTcklWhldHX7pOtjGLm1SWp2xmAMtsjm7W9WctSqpEHbgeQ9GNTZK2KlBANEhYVNH1O+fwEMbBw52BcQO53KZPywtY2uV4QEiU227SPoJwg83gHmVVIIH8Y7M/XScH0pu4H1z7lKqeV9MYUUH2nACy+8x1osY+9ulWhQKpX1m2ikg7NtTSvjdSbaT+Xg+QbdgT1++5yT+ShfZ2W5y6wkX1RtQaeDGbZD8kmb+d9eAacbeoiDW9C6dUxmINu3iegtMrZWZ9iWKEcmPAbp5R2nT4HuI+rZNL7+1vv+AU2A1cKEqxuCNDmRsVoPNXcxKuELryCbIoG2nOyEj8/oouqWyXgHFDTka9u6ysylq4ZKahSg3jvQczl6lByFjoZpCWBMndATjzwCGI7CZshq3hxKnktRQ/ZvuMSV1I4rAUSsGvNC89ypyOUkrfmaFxYgm2aldUn2Athxw2lRsApl0h9h57H5LEGO5hsvfpk9rVXUlE+H3qyT6crIjGtTzfjfUGC+mU/bxbK8XJUKavwQisg3ouYyozv4GbW0q3RrCTWePaKqWTCSIYfLIzS6a4Se2z23+MeZpSYo+bs0GyuMCbftgDWMpi0mlw1ojQ2KwUTn2lLpNA4QfPWBJQRR/x3LStjblDPES6R8KP25fjkaPiCnAtqu9ZIZeyRz0fbfPLmj22dSonNTbr9gO5ETAZCKtdDYZS2UB6EK5mbW0XyN6hSgIrA0igDt2hRFSmg+YLDrz5vpA4mwAnm88JjHZbhHzl+kE00U6BjGZnOZ8gNz/m6NsYTV5zvYpyMtkrRQ4NBjOkYgcVwqUGeZnqAjVAnig3QLeCAB3GxIYFCokcn0o8JBRy7CrJLDll9CFvVFNuUD5EXsaLugZyo/gbSNXajeFDOaOXrXGPKu9UCoNZbrcuhy5UgW1eLnS1HBeB4BJCHtdT1JRgX0jvrsx3Bqi0Z+7GgePnMwn/w+7kiswrbeG7ibfArFPznnsw45FEx8ZoHigqEU8opnvkeGFls2yx6CKPGZoUp1mpczq9VdqKegRK2h/cDaNqnttcobISarAKB0m9U5mVeVXhlHquDL/m2jY1PJQ0wP2CKeSUpHS83ohGAp4hYPLWjbsD5WXJ57ZbIlWkCl3IYVVlhR/RyXuLHwpck0e++tqG+e8dE8Y8q0CdZm3nNSPZOheH3KYO02a9ZnU06bYcTiNKFDYfxqmZwySRRX1+j/jJeQ/vXKR45dGyYZdpIgczZGWgtvWkP3vm8gCdATEX5owDJrmCeuxLf5YaAW6okepAmgSmEOlGKQkkaJmI5PARmi32T594+d/3LkldqCt4tb8Tw52OuFlA+hhShTXMvK7i5E1rV1CBH8j5GsstMhcUj7NrR69agMey0n8RLPjqWyu9I80DUzK/B1kuQgHpiRNJebkV0BMYPXp1Hmo3Z0ZO0KRTxMTGEts/XtznbqgRB0WPoK4IN2pweeZuyS8AvXusi57rIFhRsVCa9ZTmgPmvwzj+BniS+iDjpF35MpY5TXK5ijdlkB2E8pfsqgi/LJVolkWkpbOtS1wGimoyx8c/NKeERSuVTVnLvJeVZr0UYCbTOALAYOg07Cc8wWRTJVB6YV5K42YYHlhW3AlZCVJNl1FXy2Hc6t322/nP+ZNCON9b5QrI5NONrY+y6AjQ6ood42EfCMLON02KAyiIpGnO1+hCUHaD72W3tcHc2elCgsif3vmBlwnd5qj5Pi/mR3Q4ERsgEs7tCvWNrpvcqgDWJriPiKbm+5G0dds8034pEohSNufJIzYy3Q488oMZRU/sF3bjthprGQM1j6jYkUEl7p1eckV8MI3TlqMMziKR5I0gMoFKrXsqN6tCjjI78Z6uEJR25OIgvvMjuFW76ftQNpeQiWw+2W0lo0xt92IgSAmur6XG5TZK6DtYyMgmBgaySub/3ZC0G3fiyXEKLDb40qfch9zs0opxu3vTVo3Lzn7+iywuuMos0mA4R7jTpw8d2znsMDzlmoU2Hj3C3wrTJ5bStrnzl5ahlsnpeIcrtQuuRKZ5FJzDl9tswNWHT9Y/no0zhbwhB0lFGeRXNvzhACObU9oOXnns0y6VdI+rIlQuEJLTKR5dUTxchphVLqj5/L5RUofiMXzOviw3793PYLpeflJzasEwmNjFGECnya2hfdeGeh7GZ7aUaDZYpXNtmhestNvgwDLUWsrXJmsfBoobV5qUC1+P6nesl0YYvufhhc+VcVibzSgnW6Pc+JjskfB3aIe8YEdlTPCDQo8JbLZPw2SVKJ3uO0r1hpRefXFwx3qPozBuU6m2Ev083WKeuQVTckGLt8dnPmDFBI65+s7GEJO1i0WNOMC5qQvlQKYUDDl6zn+0CqND7g85z7E1hwCOnLLU/QpmvpNXqwyypk83KzrdIsxDWD/Y8mlcvTZ1ffau9UaKECScVFyysvNEuoGadiTKDBVPNa/w1rwvC04flZ136mVLpuGNosbeKbzRhvdQyrQyqu4MCL6vxPsdV4M/3jJrCKQ/B4J8U7Gho9415mjkOHSV1ZAQY4432OVknvBOnY8TW/FUc+eulCtDcK4hs28RaTiXW6A0FHV2aEE+m2xU5xBlwlSUKkhnCqWaJTP6vqRUO243b7b3i7dBGNnSEGbGmJbEuUIu29NZUDrd21EKcuywucyLXPNcLFK5YTGpa98Z2lJpVY/4Z3PyCMEW2gqdabrCammoZ6zS3WUChWW31jxqlbPWKhQyD9sMZWOAjBarOxtfufSXbhWyogwCWXTgJi/NfPIzk4V4RZOlwValW/WDuQ3JIBSJIjqL0/lSt4/LBi5vNTLBxSbGWv0uoyjaxitJndLp9lxAatpfELuxVzDTi7Tz91zGtXxDQT8SwLAE3kuNy6sezSmGd08ycLSGLo3WJj3hoLywkm5YoVK8SQlI+wGhS0O0eAMz30hjtmjzNvtOlSIeZ6lmQW2s0TkY6c349AgV8r4iptsNa4mDe5RzfsG4TgxFap2diuGme5Rsevey4yWMi5pmgTt8smNTNu5znIf/95mtaYrC3v7Odlreoqm4K8Dz2KnuF0qyDKDQ9CwQ6VKEdhP3DYFGKSiEvLWIXECIS4PcH7O8+Dnx5mbwJHJmpghymIJsROKQFeMOsY2fpN5Oqj6MnGXuvOSXZK9tgVxtdlaLVctzBxzGm8ptOb/Hly2pBfqLfhZTXy2NFW1WISvJUU0ktbzsJ34WSM8cyQTTIlNl5dR5bZ+eeJsP2X4JXah8TLs79qtVcsBebBYZzuPNeHd/d39hN46r5Jt18Bf79Ob+otsH6OVPj2lvTLpDLtyPd/E53QdY8JMgWJLN2QSeJBY9cqjJe3BLHa0wDZLhgwwQJBcnFW/zJ/fwiPTN4y9r8uLIwhrpxcm67H7T8Yu3N6HbJkl9tp/O73N6Enk2O5ajLPU2kJETge7UkIbEzixgEz/ePrh9OyE0cPvm7duLyudLFEx2D37/ZvLmzQkWXsfbb0/28GV6ebHPM8WKq/hTz+1np+LKk4P2G7nR27ezi8r79IjHdBpHQcnwujMwSwOE7ePYFaeIqE9VneeqTltvk+Ttd94z3gCuvkGu831FeRHNVc4qkPCCejC7riiBYFDXVtLicSZxSCqnar8fNt90ktbbfhNriaCcC9qnHnU522lG5h9uX3avbjy9lg4jh/EXwINvXoe6ejYbXb85suxz4heAR7P9SK1vz0Z4AVtZ3v14Ns1/ruSsBtq9ABS7IXV96ljvPpiN+1Now2m7kbw59zLrV/NddvBo92h6B7mZQ95qcTGkOtaEik0qD1qIudRUZIT2irZcxFToqMSf+Gvx86vzeMXNEYegcXzjKZ1teAg/nlE1BiZ3cJsko6OnMFrG1MowltUumtgaEoM3ladsrdITRJ4/Gb329JOodjvuX/0qTksgY4LtVHZl/B5uRIe0P8TVjOhtym5SrE46TCSE8DskRaxl5ye8vZTCjl6xaY3jJ7zn5c23n5MPIq+lV/8gOmwMLl/f15pyJ5plomcs4xHj5LX3lfn0kMcvN0IaNIWEha1bXAUCiAyFB5SiMQkwBdp2lXQAbKSO6isGzcrtVfS2Jwk3/O9lQEpFh63ry3PvF/jw98noFSsD8aaT9KfeXyjwdzgAf2283Z6+57JmbiTwOJg4X5pdwFvUp6FoTRnQ785jtabdtEg5cDFIUyvoLTWB4h0Z++Ba5GFrMjr3vrI6T4OXR9FPuDbwnCxhb0XHyPCpxkeP4MYowwmvdvv7IfUsDTtBSqYp7wYJEP9mWLumlzlKJYpaAdVZ5eKljl62z27HJFu8x1mmJV0YTn7rxZ+W8s1LqnA/ZOKotkD1yHi7NZr0f/nXUMDbb5+FTqui+puzhPiulUtVSRfouWWjFqlv1E/+TkCIn2EaHWysaltvVWcsW5v6ekMHPox+6z0seNsJaV60ElE42G2Dnq8tY2Z6dzU6hMVa3rpNm1pmVAOEwLnmSxspHQlrWt0Ltye9Pr6ztJUev5SdFLaev516rdZQ2tOUg3IRodltnntssE26KUdlKkyOO6+9Ik9eAbfjjdle4E40wuOmVL4lZchmFoUEipteXE+S1nHksgI5n4ZMaSOMP769MfVkCF/DUYI/InVMzr1y+GXtatifPnGb7y3/5hWpzDGkrVL/sQmldH4grk2+jeuXk/7Ne2suNUxJuKd54wTM8txjbB2pDOJRyfWw/eu41qfiv01xC6tj71w/gmtqJO1zye3gNam8wTPfb8Y014nf/zXdCQqOtI8q3CF7X8vZNYrUccS2ZsKQSbjxAj/DXFIkXVx6VofZg9hrKEPkihSWSJi8vu9Vz76/TmZuI47e5G4U9PbPr/4NTij5JSIjFct519397fZsH84SWgW5PZQVggs9d44KtVbJOXE+4xJ2mgW1ej0/m8Ye9KxHHzsg7UeHkMzV6VnrtoWQ6C2VNNcNAzB6DKY9uP22zvp42CbyLM9qQBU8quVTq/KrT6TaSo3tDqkjTR/8Q9LE6z/ikVfeqejSjvXn1F4hB9m5+tWGq6Vo2jQ2fPX27fdJIzlRtsg4UQrlNO4FO6A49i20MTZuk7KtgY1B3B4Nk9fvr7nzVTwhgesT0cvGCM5kSeXceUxSz2C/DqAT06gUdZskwdYUI2DFt43r1omiKjbpnBctBrXrQWeq8GSqgN5sc+U7cF6BosYeK4Pn6gTkMHG99yEBKQp91PqE66GhIncuzsMfB7vtFgV+MvTROYEuBvykC29eV4EarqAJq9mpCOTtrme7yTTPnvfBLW9Foee9s5300xtd0i4dgcLQBZrYhaNYJXfXvyGSy9blESwIYLYrLlVMJjzdu2ppd1MgJCzS/V6de/cWszw8T0PBB7Pz+KPbTv+q9paHRpTMTffpPmdX1DL6IngYRhIjulKVNQSp3JwLsmHnmvmUjdptn3FV0u12rvaeyrEHG0TC5Tn8HRwuYRNqI/FRZJ/XW9ftU9iBrTf7rW9me58qKa7af5gkb/hGw/7wxvvwIWdZJIiEwjdZRL0xbJ+vgyO5oKjmp5NF9eZb/uZtY0IDSYvCHt73c+7Bjpq99j89Mw/d2XIUQifDN7P9DdKWwfeEFImGDSgqYUT8d9ujarSRVgKpI50Y8UnwUJN3R8Bble06gducrsPPWu0T3o998D0pw9Ya+UxWxwGCNR950OFDJ9wG0PUXt9IL+dkL6CM1ySnSLH2wvn17Kzeqfd9vtAgMGxEPkfDhQ8TRPMePiMfgVxg6szoAi82k8Jtv8wkXlG8Dt5FREglxnffvsWPPnP4kOd/5uUSqr7k2oDZpBm4qOQvtVaAhBu6K8hFL0IW1mHsN17N4TT5QuUcuWf3i5TXNMcduS/3VXgzspC1FygHwwi+iGhe7PT46hHP37RZHzjUo5iUBSbIItbYJv3MuxafdVgM0huEnPJoi3vG/BMGH5O1gEDRg9m7RzI+OgDHTblCEVQ/5SQNBjs/HCei0BXCBjRB8j13Ny2g6x2xyu/eFWqIR3BltgkXaRm0zogtRGqGgRcrwgdQ0wQWI7cPcn3pUsQd3HpoVupFyBQjY2IzHtoEoiN5h63xnlau4PCrz2/uLS7SdlnYgUMLGZhS9vKShEVZM8kHkej8Iwp/evtmjXD4If4Fo2p3sfblKgS0WXYj9MHr+PfU+d7ISXshtDg0kNttfWuPcerfd7ZD9IKvdXKT5bkCWhRzdkCb71lyct97Ht0D3tIba1eV5LGc2SYDgEhMxrkGOlj7gHer9KQB0RNlA+9x7qLlxH6otd9hHVB9PvXWpPJAyNK72LDC6WYwPm9eT1/G9P/LySA36fRqm4J4XPezV0dMlTQuknV1SugbXOJnUVnnUZXtzE9Ke0eCdj2FSpKe7Z7Nha1oBTvBd846Dtorz7QnU3tLxbf+BWlPN9hFCVnDvHZqpu77xomWItjGGR9FRzF6TTtBqV54urUIxm5O9SLoZYb5FYIQ7xO/ziNVUxTTtZ2lrYxdO8ze3SfP2xDO8xZjy2aJaYUBR619PI2+TfM6SR7lG8m8Vb/ldL/orev0vFW89jp/T1vHZsXroGhlR/bt1tuendXggiQXqYJZ8x3HBrJs8HVaB6AZjX5abwmddtd7OTviAoiBXXKat3lJ7OSO3eLFH3/3FT89cAoyV/eK5dMpmx2Dm+7+Rl8uugPf00KVsEV7wuI3+oiY3ghteCA9cl+0kXo8/Ossq9rcXCPqfBIYLt747qjSMXCfMGhWG2/PGWBA/d6+//iJYNdI2O5aTOS1y1+NArdLr51+7yahISvM0IGpMWqY/8eL5TU9PqxUVyxlxvDtAFUuSSEmVhs91y5pj93JBdtKHx7uM3FWyFdWklWZiyX9fdecTySWEK2xW2lk1uS/vVHrux3SODNeANYUpzWfKiDvb4WpcmJbWP4d3DLMmGdDl++lLNyMc8ukRxmxwvRUaFRg5HUUKe9mNcIk3r9h/FaS7/KXUStOveLFRcCfjBW6DBPDWQzkgbsl17qQrJQVGNx7FXs9KEVHLuByp6odySJ5yQERlozLEJCsbhviIwLhccN9zp3Td2Wvq6qGyv1WlY8G434ZOj+PSri6njBxI4zKPIFhdeyg3UUGswmB+EGpodSkrrHLNF5q4JQUJm5VVTbZRRks/yJ2W4w6HCFn75MgGd5mSM5WzQ3mCDbO0btPiic7ONgnTJoaZ93v5dSE9Byg77c2kGwitmp9M7MrveMS9ey5dWXMddCMwan5+xMbm/Pxend7UuPqBzk4vTsNjUat0bsy4wV/3PLeRzXDhV7hJmG1Dy/nNgKBZE0O5Y1mlUAwGPKFJMONmtuiWCzptyPLtH6b9Pu1OujShSJbGF5T0WwK+h06Pe+VeCOsF1c4+pEhp/phdpBH9XJVuAKnypl3ceGjdqXDpIYZammxKGWtDvRY4vc6taknuabw7tmmJ2o2rLGKR9z7kCnn85F2VTaOsLcXUCWJDC37iuqBlPpQONwEM2/wJLlEymGEWkSvTTubYPgzckWUayfMzOrzIRuo9RE32Kews7NKKHI/zY3rWh8EHK/eCDTnikTIeLGaTz7l7qtU6jwEr9YFZlB26SMm8oEw9ZTjcNbNWUPESNTE2QTHrr+bOQbi6wWVYfJXclPcBO7oNdg9PD6on4cYydbpskHto9OOSb5YX7eI9iMaLD2wxJIavQfwmtgcnXpCvHpyeWLUmtvpBcHDqqeigugds/0HhZ9unxzb4SbAYrG0YJBAf4qO9z3niWcMnwmtXd6sHJxVt86cnVSmF/a/nvzt5EoMF8f7OTvy0FFhb+iI2qzq2end/F4g1jIPlMHz6lwtg4MvXwAf16Wli1+PQrMSfLN0LD6beYnwAHPR5bDffjetfx/GHf1IKYht/tB/G79s6FYRAf7y57OUvTqfe2fTsIt6tn54hutGu0rLCUxRtWvznHGDGKthTAO8QKryFB0f7p/uhUrFPoSFUXvyjc52Laq/V819GChQp7z+HUX7qPX7/ARKJ+3TWnHp5hNupEr4S1SqbeHmwH6vFCCLYUN6Lf1an3n+78dpHB1OVJzRMs3Pb7b24ulsJa+d76qASb+/vf1apVuL8SWW3fvL3+b2oWvXi6kcVr3RQCV/gW3HtdZzfzyPLVdXK/Wi3OvX88ONpXKWvFauHR7vgdeRVq7vfVONqfn97H7fQ5qAKSFQ7V7vrtZsv6kf14zg68XQONJY/alcOLurT3frF0cHpd7vfnN7ULoCmz87O862LaquSvzj7+uDibBofnE5jkBBHtX/NH+2enZ1ACy7288kZTQs8mOozfM3Hd78+mD5IKgen//Kgf4o7n7SPdi/O9j6+SGK7/mIGyms3CiRAPGuaJllVsN2uPJhV25WXR/GZqv+yfnHyfArxXuSRuh/F9crh0Y9u8nTBP0T1Su011LsGoj6+yU/js0r96MX5A+IC/qrR1+qV+vGD6UK7Uq8cqLNKfnJ6XMetf/Tt4dHf7mnvozezkxgX4n7/CGuVCLUFEvLTBVx3/NHstA3q1IPXEO/+wfTT+q9xp/r+gymRU6lW65UXr5Ek1r47OHp5Hrchgdpr8H3q5WIi4TyPC71DkECUXOzbs738DDnmEWne4XeVYGkrOmiDld+dnuTbX0NfBaIEn4EL0xCrPd6eVatYxP5/utmeKrA9qn9NJFT+CnfeqVeeX4CEc2/Z1G68yuG3Ub06DWs39eNtaKLHJGxPH0xjIiFs//Lg7TT8DUiIiQQkmQ/a030bV9XBqAJBKLYT6SwH5rP23sfT4BswHCSrPajJCzB5e5oKov5Pz/Ha1pkakOCDhFjVzkHCDGLF16AL7z+fxrXf/hRfU0SC+ubvKwdJ5TcVkGDrX4OzXvWgfRRHBx5J84bSRqTrVY9biMojQYDPh+f77ZMDSDd+ABIeQLCV+kmFdIF+xwX1avv4R6+9cgQuxCQcOI3DI9aAddKFF5Bfvn1S//bBtJpUTqEJ9SpkBS7UptWTA3VYsdHLo/zV/gvAXu/5rLLLRgkfe9A4OehXWycHs6OD2cXub86fnZG61C+aX9dm1ebJg4uzCn5vHtem9fP/dxHr3bOLX219Bov4snZxgQzkIvk/dLbb8dnFwaxSm51dfFb/t7Pjs9NzXf/uIDnebUPws6Pa6UUMT3EBQ8P3rRefzZJjGxao8bDrznlbr2rYOX57Sr/Bxqtxvpqv7hv4Be4U4rf9ajUKcUnlL0y++gcW18cRLoxMzJ1Euaga7Vaqe7vkW/a36R28UV3E7xa4tFpVYbX6d/Hml7i1xzE6G0dZjNSnO8qTwz0RR1aRI0QEp9eVFiAd5SKu8eK9BeTNKjbwjjakUKfTXqiHuyhyrvfwej3yBIGvK7qRh/wfIIlutqjtVkRAciHg3twTxOu/iSNNftzqHeofrG8BBtOOWP3Elt+Lw2CHupdxNibry4Ggj8JPAUIB4zaXZboxBloIN5aeUF86Nhx8gzI8UmwX6Xqr3g3jcvCEEvtAx/YHJ6cxTiBwL2ekrrkhsqBMeIa3uzwK5ke8BTlE45yb1ZXRHHeeoJKJB6xMziHFP8sEcghq0eYlnvVYIaxclmNqeK5JytTZSISD6/MdfYWcm4p6TAmIjL8oXU7HNHnPYToWRBjsoczUynYYTQOfJh2KYm9s+LRRox7x/9uBO1ZQeJAdsZ7uy3cnDmrrJrplH64hEbq5ED0/x1PmDpQMxPz7c+d59EO7+SU5s5Ku/hOfhWC1DIrQcMP8DFmbjlaljUbDA1WClNP/4xQefSvf2RMsUNF1OO4cJZGetWPS08/lnCKfT1n8/6A9Ozw6/OsmAAAAAElFTkSuQmCC';

class OmanSmartErpApp extends StatelessWidget {
  const OmanSmartErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arwad International Food Industries SPC | أرواد العالمية للصناعات الغذائية (CR: 1658937)',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A5F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
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
// مدل پروفایل کامل مشتری (شامل سقف اعتبار نسیه، تیپ قیمتی و کد مالیاتی VATIN عمان)
class CustomerProfile {
  final String id;
  String name;
  String phoneAndAddress;
  String vatinCode; // شماره ثبت مالیاتی عمان (VATIN)
  String priceTier; // 'عمده‌فروش (Wholesale)' | 'سوپرمارکت/هایپر' | 'رستوران/فست‌فود'
  double creditLimitOMR; // سقف اعتبار نسیه مجاز مشتری

  CustomerProfile({
    required this.id,
    required this.name,
    this.phoneAndAddress = 'مسقط، سلطنت عمان',
    this.vatinCode = '',
    this.priceTier = 'سوپرمارکت/هایپر',
    this.creditLimitOMR = 1000.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneAndAddress': phoneAndAddress,
        'vatinCode': vatinCode,
        'priceTier': priceTier,
        'creditLimitOMR': creditLimitOMR,
      };

  factory CustomerProfile.fromJson(Map<String, dynamic> j) => CustomerProfile(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        phoneAndAddress: j['phoneAndAddress']?.toString() ?? 'مسقط، سلطنت عمان',
        vatinCode: j['vatinCode']?.toString() ?? '',
        priceTier: j['priceTier']?.toString() ?? 'سوپرمارکت/هایپر',
        creditLimitOMR: (j['creditLimitOMR'] as num?)?.toDouble() ?? 1000.0,
      );
}

// ردیف سبد سفارش چندقلمی مشتری (Multi-Item Order Cart Line)
class OrderCartLine {
  final String itemId;
  final String itemName;
  final String unit;
  final double unitWeightKg;
  final double qty;
  final double freeBonusQty;
  final double unitSalePriceOMR;
  final double unitCogsOMR;
  final double lineDiscountOMR;
  final String batchNumber;
  final String expiryDateStr;

  OrderCartLine({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.unitWeightKg,
    required this.qty,
    this.freeBonusQty = 0.0,
    required this.unitSalePriceOMR,
    required this.unitCogsOMR,
    this.lineDiscountOMR = 0.0,
    this.batchNumber = '',
    this.expiryDateStr = '',
  });

  double get totalPhysicalQty => qty + freeBonusQty;
  double get totalWeightKg => totalPhysicalQty * unitWeightKg;
  double get lineNetRevenueOMR => (qty * unitSalePriceOMR) - lineDiscountOMR;
  double get lineTotalCogsOMR => totalPhysicalQty * unitCogsOMR;
}

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
  final double freeBonusQty;
  final String unit;
  final double totalWeightKg;
  final double unitPriceBase;
  final double totalAmountBase;
  final String batchAndExpiryInfo;
  final String multiItemsBreakdown;
  bool isStockPhysicallyDeducted; // آیا انباردار خروج فیزیکی کالا از سردخانه را تایید کرده است؟
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
    this.freeBonusQty = 0.0,
    required this.unit,
    required this.totalWeightKg,
    required this.unitPriceBase,
    required this.totalAmountBase,
    this.batchAndExpiryInfo = '',
    this.multiItemsBreakdown = '',
    this.isStockPhysicallyDeducted = true,
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
        'freeBonusQty': freeBonusQty,
        'unit': unit,
        'totalWeightKg': totalWeightKg,
        'unitPriceBase': unitPriceBase,
        'totalAmountBase': totalAmountBase,
        'batchAndExpiryInfo': batchAndExpiryInfo,
        'multiItemsBreakdown': multiItemsBreakdown,
        'isStockPhysicallyDeducted': isStockPhysicallyDeducted,
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
        freeBonusQty: (j['freeBonusQty'] as num?)?.toDouble() ?? 0.0,
        unit: j['unit']?.toString() ?? 'بسته',
        totalWeightKg: (j['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
        unitPriceBase: (j['unitPriceBase'] as num?)?.toDouble() ?? 0.0,
        totalAmountBase: (j['totalAmountBase'] as num?)?.toDouble() ?? 0.0,
        batchAndExpiryInfo: j['batchAndExpiryInfo']?.toString() ?? '',
        multiItemsBreakdown: j['multiItemsBreakdown']?.toString() ?? '',
        isStockPhysicallyDeducted: j['isStockPhysicallyDeducted'] != false,
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
  final String taxInvoiceNo; // شماره فاکتور رسمی مالیاتی فروشنده (جهت تایید ذی‌حسابی عمان)
  final String vatClassRule; // 'standard_5' | 'zero_rated_0' | 'exempt_non_claimable'
  final bool isComptrollerApprovedInputVat;
  final double recordedExchangeRate;
  final String recordedCurrencyCode;
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
    this.taxInvoiceNo = '',
    this.vatClassRule = 'exempt_non_claimable',
    this.isComptrollerApprovedInputVat = true,
    this.recordedExchangeRate = 2.60,
    this.recordedCurrencyCode = 'rial',
    required this.date,
    required this.topic,
    required this.category,
    required this.title,
    this.note = '',
    this.createdBy = 'مدیر',
    this.customValues = const {},
  });

  double get vatAmountOMR => hasVat5Percent ? amountOMR * (5.0 / 105.0) : 0.0;
  double get netBeforeVatOMR => amountOMR - vatAmountOMR;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode.name,
        'source': source.name,
        'amountOMR': amountOMR,
        'hasVat5Percent': hasVat5Percent,
        'taxInvoiceNo': taxInvoiceNo,
        'vatClassRule': vatClassRule,
        'isComptrollerApprovedInputVat': isComptrollerApprovedInputVat,
        'recordedExchangeRate': recordedExchangeRate,
        'recordedCurrencyCode': recordedCurrencyCode,
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
        taxInvoiceNo: j['taxInvoiceNo']?.toString() ?? '',
        vatClassRule: j['vatClassRule']?.toString() ?? (j['hasVat5Percent'] == true ? 'standard_5' : 'exempt_non_claimable'),
        isComptrollerApprovedInputVat: j['isComptrollerApprovedInputVat'] != false,
        recordedExchangeRate: (j['recordedExchangeRate'] as num?)?.toDouble() ?? 2.60,
        recordedCurrencyCode: j['recordedCurrencyCode']?.toString() ?? 'rial',
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
  double reservedQty; // مقدار رزروشده در انتظار تایید خروج فیزیکی توسط انباردار
  double minStockAlertQty; // نقطه سفارش / حداقل موجودی مجاز جهت هشدار کمبود
  String batchNumber; // شماره بچ / سری ساخت سردخانه
  String expiryDateStr; // تاریخ انقضا (YYYY-MM-DD) جهت استاندارد FEFO لبنیات
  double avgUnitCostOMR;
  double defaultSalePriceOMR;
  double wholesalePriceOMR; // قیمت تیپ عمده‌فروشی
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
    this.reservedQty = 0.0,
    this.minStockAlertQty = 10.0,
    this.batchNumber = 'BATCH-2026-01',
    this.expiryDateStr = '2027-06-30',
    this.avgUnitCostOMR = 0.0,
    this.defaultSalePriceOMR = 0.0,
    this.wholesalePriceOMR = 0.0,
    this.defaultCartonPerUnit = 0.1,
    this.defaultNylonPerUnit = 1.0,
    this.defaultLabelPerUnit = 1.0,
  });

  double get availableQty => (currentQty - reservedQty) > 0 ? (currentQty - reservedQty) : 0.0;
  bool get isLowStock => currentQty <= minStockAlertQty;
  bool get isNearOrPastExpiry {
    final exp = DateTime.tryParse(expiryDateStr);
    if (exp == null) return false;
    return exp.difference(DateTime.now()).inDays <= 30;
  }

  double get totalInventoryValueOMR => (currentQty > 0 ? currentQty : 0) * avgUnitCostOMR;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'warehouse': warehouse.name,
        'unit': unit,
        'unitWeightKg': unitWeightKg,
        'currentQty': currentQty,
        'reservedQty': reservedQty,
        'minStockAlertQty': minStockAlertQty,
        'batchNumber': batchNumber,
        'expiryDateStr': expiryDateStr,
        'avgUnitCostOMR': avgUnitCostOMR,
        'defaultSalePriceOMR': defaultSalePriceOMR,
        'wholesalePriceOMR': wholesalePriceOMR,
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
        reservedQty: (j['reservedQty'] as num?)?.toDouble() ?? 0.0,
        minStockAlertQty: (j['minStockAlertQty'] as num?)?.toDouble() ?? 10.0,
        batchNumber: j['batchNumber']?.toString() ?? 'BATCH-2026-01',
        expiryDateStr: j['expiryDateStr']?.toString() ?? '2027-06-30',
        avgUnitCostOMR: (j['avgUnitCostOMR'] as num?)?.toDouble() ?? 0.0,
        defaultSalePriceOMR: (j['defaultSalePriceOMR'] as num?)?.toDouble() ?? 0.0,
        wholesalePriceOMR: (j['wholesalePriceOMR'] as num?)?.toDouble() ?? 0.0,
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
  String exitSlipNumber;
  final DateTime date;
  final String finishedItemId;
  final String finishedItemName;
  final String unit;
  final double qtySold;
  final double freeBonusQty; // تعداد اشانتیون / نمونه رایگان تحویلی به مشتری
  final double unitSalePriceOMR;
  final double discountOMR; // تخفیف خطی / فاکتوری اعمال‌شده
  final double unitCogsOMR;
  final double deliveryExpenseOMR;
  final bool hasVat5Percent;
  final String customerName;
  String paymentStatus;
  double paidAmountOMR;
  List<String> paymentLogs; // تاریخچه دریافت‌های مرحله‌ای (اقساطی) و چک‌های مدت‌دار PDC
  final int partnerSplitDivisor;
  final bool isReturnDoc;
  bool isProformaQuote; // آیا سند در وضعیت «پیش‌فاکتور رسمی (Proforma)» است؟
  final double lockedExchangeRate; // نرخ ارز قفل‌شده در لحظه ثبت معامله
  final String multiItemsDescription; // شرح اقلام در صورت چندقلمی بودن فاکتور
  final String createdBy;

  SaleProfitDoc({
    required this.id,
    this.exitSlipNumber = '',
    required this.date,
    required this.finishedItemId,
    required this.finishedItemName,
    required this.unit,
    required this.qtySold,
    this.freeBonusQty = 0.0,
    required this.unitSalePriceOMR,
    this.discountOMR = 0.0,
    required this.unitCogsOMR,
    required this.deliveryExpenseOMR,
    this.hasVat5Percent = false,
    required this.customerName,
    required this.paymentStatus,
    required this.paidAmountOMR,
    List<String>? paymentLogs,
    required this.partnerSplitDivisor,
    this.isReturnDoc = false,
    this.isProformaQuote = false,
    this.lockedExchangeRate = 2.60,
    this.multiItemsDescription = '',
    this.createdBy = 'مدیر',
  }) : paymentLogs = paymentLogs ?? [];

  double get sign => isReturnDoc ? -1.0 : 1.0;
  double get grossRevenueBeforeDiscountOMR => qtySold * unitSalePriceOMR;
  double get netSalesAfterDiscountOMR =>
      (grossRevenueBeforeDiscountOMR - discountOMR) > 0 ? (grossRevenueBeforeDiscountOMR - discountOMR) : 0.0;
  double get totalRevenueOMR => isProformaQuote ? 0.0 : (sign * netSalesAfterDiscountOMR);
  double get vatAmountOMR => hasVat5Percent ? (sign * netSalesAfterDiscountOMR * 0.05) : 0.0;
  double get totalInvoiceWithVatOMR => (sign * netSalesAfterDiscountOMR) + vatAmountOMR;
  double get remainingReceivableOMR => (isReturnDoc || isProformaQuote)
      ? 0.0
      : ((totalInvoiceWithVatOMR - paidAmountOMR) > 0 ? (totalInvoiceWithVatOMR - paidAmountOMR) : 0.0);

  // استاندارد حسابداری بهای تمام‌شده: اشانتیون نیز از انبار خارج شده و بهای تمام‌شده دارد
  double get totalPhysicalQtyDispatched => qtySold + freeBonusQty;
  double get totalCogsOMR =>
      isProformaQuote ? 0.0 : ((sign * totalPhysicalQtyDispatched * unitCogsOMR) + deliveryExpenseOMR);
  double get netProfitOrLossOMR => totalRevenueOMR - totalCogsOMR;
  double get profitMarginPercent =>
      totalRevenueOMR.abs() > 0 ? (netProfitOrLossOMR / totalRevenueOMR.abs()) * 100.0 : 0.0;
  bool get isInLoss => !isReturnDoc && !isProformaQuote && netProfitOrLossOMR < -0.0005;
  int get daysOverdue => DateTime.now().difference(date).inDays;

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
        'freeBonusQty': freeBonusQty,
        'unitSalePriceOMR': unitSalePriceOMR,
        'discountOMR': discountOMR,
        'unitCogsOMR': unitCogsOMR,
        'deliveryExpenseOMR': deliveryExpenseOMR,
        'hasVat5Percent': hasVat5Percent,
        'customerName': customerName,
        'paymentStatus': paymentStatus,
        'paidAmountOMR': paidAmountOMR,
        'paymentLogs': paymentLogs,
        'partnerSplitDivisor': partnerSplitDivisor,
        'isReturnDoc': isReturnDoc,
        'isProformaQuote': isProformaQuote,
        'lockedExchangeRate': lockedExchangeRate,
        'multiItemsDescription': multiItemsDescription,
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
        freeBonusQty: (j['freeBonusQty'] as num?)?.toDouble() ?? 0.0,
        unitSalePriceOMR: (j['unitSalePriceOMR'] as num?)?.toDouble() ?? 0.0,
        discountOMR: (j['discountOMR'] as num?)?.toDouble() ?? 0.0,
        unitCogsOMR: (j['unitCogsOMR'] as num?)?.toDouble() ?? 0.0,
        deliveryExpenseOMR: (j['deliveryExpenseOMR'] as num?)?.toDouble() ?? 0.0,
        hasVat5Percent: j['hasVat5Percent'] == true,
        customerName: j['customerName']?.toString() ?? '',
        paymentStatus: j['paymentStatus']?.toString() ?? 'نقدی / واریز بانکی',
        paidAmountOMR: (j['paidAmountOMR'] as num?)?.toDouble() ?? 0.0,
        paymentLogs: (j['paymentLogs'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        partnerSplitDivisor: (j['partnerSplitDivisor'] as num?)?.toInt() ?? 1,
        isReturnDoc: j['isReturnDoc'] == true,
        isProformaQuote: j['isProformaQuote'] == true,
        lockedExchangeRate: (j['lockedExchangeRate'] as num?)?.toDouble() ?? 2.60,
        multiItemsDescription: j['multiItemsDescription']?.toString() ?? '',
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

  // شاه‌کلید / پسورد مادر اضطراری (Master Recovery Password) برای ورود یا بازیابی رمز ادمین در مواقع فراموشی
  static const String kBuiltInFactoryMasterKey = 'OMAN-MASTER-2026';
  String _customMasterRecoveryKey = 'OMAN-MASTER-2026';
  final TextEditingController _masterKeySettingCtrl = TextEditingController(text: 'OMAN-MASTER-2026');

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

  // ==========================================================================
  // فیلدهای ارتقایافته نسخه ۷.۰ (اصلاحات ۱۲گانه کارگروه مالی، انبار و فروش)
  // ==========================================================================
  List<CustomerProfile> _customerProfiles = [
    CustomerProfile(id: 'cust_1', name: 'مشتری عمومی بازار مسقط', priceTier: 'سوپرمارکت/هایپر', creditLimitOMR: 500.0),
    CustomerProfile(id: 'cust_2', name: 'رستوران‌ها و فست‌فودها', priceTier: 'رستوران/فست‌فود', creditLimitOMR: 1500.0),
    CustomerProfile(id: 'cust_3', name: 'سوپرمارکت‌ها و هایپرمارکت‌ها', priceTier: 'سوپرمارکت/هایپر', creditLimitOMR: 2500.0),
    CustomerProfile(id: 'cust_4', name: 'پخش عمده مواد غذایی', priceTier: 'عمده‌فروش (Wholesale)', creditLimitOMR: 5000.0),
  ];
  List<OrderCartLine> _orderCart = []; // سبد سفارش چندقلمی مشتری
  DateTime? _periodLockDate; // تاریخ قفل بستن دوره مالی (Period Closing Lock Date)
  final TextEditingController _periodLockDateCtrl = TextEditingController();
  bool _useHistoricalRateLock = true; // قفل نرخ تاریخی ارز روی اسناد
  bool _allowFactoryMasterKey = true; // اجازه استفاده از پسورد مادر پیش‌فرض کارخانه

  // کنترلرهای بچ‌نامبر، تاریخ انقضا (FEFO) و ملزومات اضافه تولید (BOM)
  final TextEditingController _inbBatchNoCtrl = TextEditingController(text: 'BATCH-2026-01');
  final TextEditingController _inbExpiryCtrl = TextEditingController(text: '2027-06-30');
  final TextEditingController _prodBatchNoCtrl = TextEditingController(text: 'PROD-2026-01');
  final TextEditingController _prodExpiryCtrl = TextEditingController(text: '2027-06-30');
  final TextEditingController _prodExtraPkgDescCtrl = TextEditingController();
  final TextEditingController _prodExtraPkgCostCtrl = TextEditingController(text: '0');

  // کنترلرهای تخفیف، اشانتیون، پیش‌فاکتور و رزرو دو مرحله‌ای انبار در فروش
  bool _isProformaMode = false; // حالت صدور پیش‌فاکتور رسمی بدون کسر از انبار
  bool _reserveStockUntilWhApproval = false; // رزرو در انبار تا زمان تایید خروج فیزیکی توسط انباردار
  final TextEditingController _saleDiscountCtrl = TextEditingController(text: '0');
  final TextEditingController _saleBonusQtyCtrl = TextEditingController(text: '0');

  int _pettySubTab = 0; // 0: فرم ثبت و ممیزی ذی‌حسابی, 1: جدول فشرده و کم‌حجم هزینه‌ها (فونت ریز), 2: گزارش نهایی ذی‌حسابی و مالیات VAT عمان
  TxMode _formMode = TxMode.expense;
  ExpenseSource _formSource = ExpenseSource.petty;
  bool _txHasVat = false;
  String _txVatClassRule = 'standard_5'; // 'standard_5' | 'zero_rated_0' | 'exempt_non_claimable'
  bool _txComptrollerApproved = true;
  final TextEditingController _txTaxInvoiceNoCtrl = TextEditingController();
  final TextEditingController _txCompactSearchCtrl = TextEditingController();
  String _txCompactVatFilter = 'all'; // 'all' | 'vat_only' | 'non_vat'
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
      'customMasterRecoveryKey': _customMasterRecoveryKey,
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
      'customerProfiles': _customerProfiles.map((c) => c.toJson()).toList(),
      'periodLockDate': _periodLockDate?.toIso8601String(),
      'useHistoricalRateLock': _useHistoricalRateLock,
      'allowFactoryMasterKey': _allowFactoryMasterKey,
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
      if (data['customMasterRecoveryKey'] != null && data['customMasterRecoveryKey'].toString().trim().isNotEmpty) {
        _customMasterRecoveryKey = data['customMasterRecoveryKey'].toString().trim();
        _masterKeySettingCtrl.text = _customMasterRecoveryKey;
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
      if (data['customerProfiles'] is List) {
        final cp = (data['customerProfiles'] as List)
            .map((e) => CustomerProfile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (cp.isNotEmpty) _customerProfiles = cp;
      }
      if (data['periodLockDate'] != null) {
        _periodLockDate = DateTime.tryParse(data['periodLockDate'].toString());
        if (_periodLockDate != null) _periodLockDateCtrl.text = _fmtDate(_periodLockDate!);
      }
      if (data['useHistoricalRateLock'] is bool) {
        _useHistoricalRateLock = data['useHistoricalRateLock'] as bool;
      }
      if (data['allowFactoryMasterKey'] is bool) {
        _allowFactoryMasterKey = data['allowFactoryMasterKey'] as bool;
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

    final totalPhysical = saleDoc.qtySold + saleDoc.freeBonusQty;
    final totalWeightWithBonus = totalPhysical * finItem.unitWeightKg;
    final physicallyDeductedNow = saleDoc.isReturnDoc || !_reserveStockUntilWhApproval;

    final slip = WarehouseExitSlip(
      slipNumber: slipNo,
      orderInvoiceId: saleDoc.id,
      issueDate: saleDoc.date,
      customerName: saleDoc.customerName,
      customerAddressOrPhone: _saleCustomerAddressCtrl.text.trim().isEmpty
          ? _getCustomerProfile(saleDoc.customerName).phoneAndAddress
          : _saleCustomerAddressCtrl.text.trim(),
      itemId: finItem.id,
      itemName: saleDoc.multiItemsDescription.isNotEmpty ? saleDoc.multiItemsDescription : finItem.name,
      warehouseName: 'انبار ۳: محصولات نهایی آماده فروش',
      qty: saleDoc.qtySold,
      freeBonusQty: saleDoc.freeBonusQty,
      unit: finItem.unit,
      totalWeightKg: totalWeightWithBonus,
      unitPriceBase: saleDoc.unitSalePriceOMR,
      totalAmountBase: saleDoc.totalInvoiceWithVatOMR,
      batchAndExpiryInfo: 'Batch: ${finItem.batchNumber} | Exp: ${finItem.expiryDateStr}',
      multiItemsBreakdown: saleDoc.multiItemsDescription,
      isStockPhysicallyDeducted: physicallyDeductedNow,
      driverOrReceiverName: _saleDriverNameCtrl.text.trim().isEmpty
          ? 'تحویل مستقیم / باربری شرکت'
          : _saleDriverNameCtrl.text.trim(),
      vehiclePlate: _saleVehiclePlateCtrl.text.trim(),
      deliveryStatus: saleDoc.isReturnDoc
          ? 'برگشت به انبار (مرجوعی)'
          : (physicallyDeductedNow ? 'صادر شده - کسر از انبار انجام شد' : '⏳ رزروشده در انتظار تایید خروج انباردار'),
      note: 'صادرشده خودکار بابت سفارش مشتری (${saleDoc.paymentStatus})${saleDoc.freeBonusQty > 0 ? " | شامل ${_fmtQty(saleDoc.freeBonusQty)} اشانتیون" : ""}',
      issuedBy: saleDoc.createdBy,
    );

    _exitSlips.insert(0, slip);
    return slip;
  }

  Future<void> _printOrSaveWarehouseExitSlip(WarehouseExitSlip slip) async {
    final dirStr = _lang == AppLang.en ? 'ltr' : 'rtl';
    final alignStr = _lang == AppLang.en ? 'left' : 'right';

    final officialHeaderHtml = _buildOfficialPrintHeaderHtml(
      '📦 ${_t('برگه رسمی خروج کالا از انبار (حواله تحویل سفارش مشتری)', 'Official Warehouse Exit & Delivery Slip', 'سند رسمي لإخراج البضاعة من المستودع')}',
      '<b>${_t('شماره برگه خروج:', 'Exit Slip No:', 'رقم سند الإخراج:')} ${slip.slipNumber}</b><br>${_t('کد فاکتور مرجع:', 'Order Invoice ID:', 'رقم الفاتورة المرجعي:')} #${slip.orderInvoiceId.substring(saleIdSlice(slip.orderInvoiceId))}<br>${_t('تاریخ صدور:', 'Issue Date:', 'تاريخ الإصدار:')} ${_fmtDate(slip.issueDate)}',
    );
    final officialFooterHtml = _buildOfficialPrintFooterHtml();

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
    $officialHeaderHtml
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
    $officialFooterHtml
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

  String get _companyOfficialTitle =>
      _t(kCompanyTitleFa, kCompanyTitleEn, kCompanyTitleAr);

  String get _companyOfficialSubHeader => _t(
        'أرواد العالمية للصناعات الغذائية | CR No: $kCompanyCrNo',
        'أرواد العالمية للصناعات الغذائية | Oman CR No: $kCompanyCrNo',
        'Arwad International Food Industries SPC | السجل التجاري: $kCompanyCrNo',
      );

  String get _designerCreditText =>
      _t(kDesignerNameFa, kDesignerNameEn, kDesignerNameAr);

  Widget _buildArwadLogoWidget({double height = 52}) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Image.memory(
            base64Decode(kArwadLogoBase64),
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 36, color: Color(0xFF1E3A5F)),
          ),
        ),
      );
    } catch (_) {
      return const Icon(Icons.business, size: 36, color: Color(0xFF1E3A5F));
    }
  }

  String _buildOfficialPrintHeaderHtml(String docTitle, String rightMetaHtml) {
    final alignStr = _lang == AppLang.en ? 'left' : 'right';
    return '''
    <div style="border-bottom: 3px solid #1E3A5F; padding-bottom: 10px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: center;">
      <div style="display: flex; align-items: center; gap: 14px;">
        <img src="data:image/png;base64,$kArwadLogoBase64" style="height: 60px; object-fit: contain; border: 1px solid #cbd5e1; border-radius: 6px; padding: 3px; background: #fff;" />
        <div>
          <div style="font-size: 16px; font-weight: bold; color: #1E3A5F;">Arwad International Food Industries SPC | أرواد العالمية للصناعات الغذائية</div>
          <div style="font-size: 12.5px; font-weight: bold; color: #334155; margin-top: 2px;">شرکت صنایع غذایی بین‌المللی ارواد — شماره ثبت تجاری عمان (CR No / السجل التجاري): <span style="color:#0f766e;">$kCompanyCrNo</span></div>
          <div style="font-size: 14px; font-weight: bold; color: #0f766e; margin-top: 5px;">$docTitle</div>
        </div>
      </div>
      <div style="text-align: $alignStr; font-size: 11.5px; line-height: 1.6; color: #1e293b;">
        $rightMetaHtml
      </div>
    </div>
    ''';
  }

  String _buildOfficialPrintFooterHtml() {
    return '''
    <div style="margin-top: 18px; padding-top: 8px; border-top: 1px solid #cbd5e1; display: flex; justify-content: space-between; font-size: 10.5px; color: #475569;">
      <div>Arwad International Food Industries SPC | أرواد العالمية للصناعات الغذائية (CR: $kCompanyCrNo)</div>
      <div>طراح و معمار نرم‌افزار: رامیار عزیزی | Software Designer & Architect: Ramyar Azizi</div>
    </div>
    ''';
  }

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
                      Center(child: _buildArwadLogoWidget(height: 76)),
                      const SizedBox(height: 10),
                      Text(
                        _companyOfficialTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A5F)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _companyOfficialSubHeader,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _designerCreditText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
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
                              final isMasterKeyUsed = p.isNotEmpty &&
                                  (p == kBuiltInFactoryMasterKey || p == _customMasterRecoveryKey);

                              if (isMasterKeyUsed) {
                                // ورود اضطراری با پسورد مادر (Master Password)
                                AppUserAccount? superAdm = _users.where((a) => a.isSuperAdmin).isNotEmpty
                                    ? _users.firstWhere((a) => a.isSuperAdmin)
                                    : (_users.isNotEmpty ? _users.first : null);
                                if (superAdm == null) {
                                  superAdm = AppUserAccount(
                                    id: 'usr_admin',
                                    username: u.isEmpty ? 'admin' : u,
                                    password: p,
                                    displayName: 'ادمین اصلی (ورود با پسورد مادر)',
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
                                  _users.insert(0, superAdm);
                                }
                                setState(() {
                                  _currentUser = superAdm;
                                  _selectedIndex = 0;
                                  _loginPassCtrl.clear();
                                });
                                _addAuditLog('امنیت - پسورد مادر', 'ورود اضطراری مدیر کل با استفاده از پسورد مادر (Master Key)', 0);
                                _saveLocalData();
                                _showMsg(_t(
                                  '✅ ورود اضطراری با «پسورد مادر» انجام شد. می‌توانید از تب مدیریت، رمز ادمین را تغییر دهید.',
                                  '✅ Logged in via Emergency Master Password.',
                                  '✅ تم تسجيل الدخول الطارئ باستخدام كلمة المرور الرئيسية.',
                                ));
                                return;
                              }

                              final matched = _users.where(
                                (acc) => acc.username.toLowerCase() == u && acc.password == p,
                              );
                              if (matched.isEmpty) {
                                _showMsg(_t(
                                  '❌ نام کاربری یا رمز عبور اشتباه است. (در صورت فراموشی رمز ادمین از دکمه «بازیابی با پسورد مادر» استفاده کنید).',
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
                          TextButton.icon(
                            onPressed: _showEmergencyMasterRecoveryDialog,
                            icon: const Icon(Icons.key, size: 18, color: Color(0xFFB45309)),
                            label: Text(
                              _t(
                                '🆘 فراموشی رمز ادمین؟ بازیابی و ورود اضطراری با «پسورد مادر»',
                                '🆘 Forgot Admin Password? Recover via Master Password',
                                '🆘 نسيت كلمة مرور المدير؟ الاستعادة بكلمة المرور الأم',
                              ),
                              style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
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
        label: _t('تنظیمات و دیتابیس', 'Admin & DB', 'الإدارة وقاعدة البيانات'),
      ));
    }

    // منوی مستقل ششم: راهنمای استفاده جامع (Help) و شناسنامه نرم‌افزار
    pages.add(_buildHelpAndManualTab());
    navItems.add(BottomNavigationBarItem(
      icon: const Icon(Icons.help_outline),
      label: _t('راهنمای استفاده (Help)', 'Help & Guide', 'دليل الاستخدام'),
    ));

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Directionality(
      textDirection: _activeDirection,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          titleSpacing: 10,
          title: Row(
            children: [
              _buildArwadLogoWidget(height: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_companyOfficialTitle (CR: $kCompanyCrNo)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${u.isSuperAdmin ? '👑' : '👤'} ${u.displayName} (${u.roleTitle}) | 💱 $_currUnit | $_designerCreditText',
                      style: const TextStyle(fontSize: 10.5, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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

  // بررسی قفل بستن دوره مالی (Period Closing Lock)
  bool _isBlockedByPeriodLock(DateTime docDate) {
    if (_periodLockDate == null) return false;
    final lockEnd = DateTime(_periodLockDate!.year, _periodLockDate!.month, _periodLockDate!.day, 23, 59, 59);
    if (!docDate.isAfter(lockEnd)) {
      _showMsg(_t(
        '🔒 خطای قفل دوره مالی: دوره مالی تا تاریخ ${_fmtDate(_periodLockDate!)} بسته شده است و امکان ثبت سند در دوره تسویه‌شده وجود ندارد!',
        '🔒 Period Lock Error: Accounting period is locked up to ${_fmtDate(_periodLockDate!)}.',
        '🔒 خطأ إغلاق الفترة المالية: الفترة مغلقة حتى تاريخ ${_fmtDate(_periodLockDate!)}.',
      ));
      return true;
    }
    return false;
  }

  CustomerProfile _getCustomerProfile(String customerName) {
    final matched = _customerProfiles.where((c) => c.name == customerName);
    if (matched.isNotEmpty) return matched.first;
    return CustomerProfile(id: 'cust_temp', name: customerName, creditLimitOMR: 1500.0);
  }

  double _getCustomerCurrentDebtOMR(String customerName) {
    return _sales
        .where((s) => s.customerName == customerName && !s.isProformaQuote && !s.isReturnDoc)
        .fold(0.0, (sum, s) => sum + s.remainingReceivableOMR);
  }

  // دیالوگ ثبت دریافت وجه مرحله‌ای (کامل / اقساطی / چک مدت‌دار PDC) برای مشتریان نسیه
  void _showPartialReceivableSettlementModal(SaleProfitDoc s) {
    final amtCtrl = TextEditingController(text: _fmtOMR(s.remainingReceivableOMR));
    final chequeNoCtrl = TextEditingController();
    final chequeDueCtrl = TextEditingController(text: _fmtDate(DateTime.now().add(const Duration(days: 30))));
    String method = 'نقدی / حواله بانکی';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
          textDirection: _activeDirection,
          child: AlertDialog(
            title: Text(_t(
              '💵 ثبت دریافت وجه (کامل، اقساطی یا چک مدت‌دار PDC)',
              '💵 Record Customer Payment (Full, Partial or PDC Cheque)',
              '💵 تسجيل استلام دفعة من العميل (كامل / جزئي / شيك آجل)',
            )),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('👤 ${s.customerName} — ${s.finishedItemName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_t("مانده بدهی فعلی این فاکتور:", "Current Remaining Balance:", "الرصيد المتبقي:")} ${_fmtMoneyWithUnit(s.remainingReceivableOMR)}',
                      style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                  const Divider(),
                  DropdownButtonFormField<String>(
                    value: method,
                    items: [
                      DropdownMenuItem(value: 'نقدی / حواله بانکی', child: Text(_t('نقدی / واریز بانکی', 'Cash / Bank Transfer', 'نقدي / تحويل بنكي'))),
                      DropdownMenuItem(value: 'چک مدت‌دار (PDC)', child: Text(_t('چک مدت‌دار (Post-Dated Cheque PDC)', 'Post-Dated Cheque (PDC)', 'شيك آجل (PDC)'))),
                    ],
                    onChanged: (v) => setModalState(() => method = v!),
                    decoration: InputDecoration(labelText: _t('روش دریافت وجه', 'Payment Method', 'طريقة الدفع'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${_t("مبلغ دریافتی در این مرحله", "Amount Received Now", "المبلغ المستلم الآن")} ($_currUnit) *',
                      helperText: _t('می‌توانید کل بدهی یا بخشی از آن (قسط) را وارد کنید.', 'Enter full or partial installment amount.', 'أدخل المبلغ الكامل أو دفعة جزئية.'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (method.contains('چک')) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: chequeNoCtrl,
                      decoration: InputDecoration(
                        labelText: _t('شماره چک و نام بانک (مثلاً Bank Muscat) *', 'Cheque No & Bank Name *', 'رقم الشيك واسم البنك *'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: chequeDueCtrl,
                      decoration: InputDecoration(
                        labelText: _t('تاریخ سررسید چک (YYYY-MM-DD)', 'Cheque Due Date (YYYY-MM-DD)', 'تاريخ استحقاق الشيك'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (s.paymentLogs.isNotEmpty) ...[
                    const Divider(),
                    Text(_t('📜 سابقه پرداخت‌های قبلی این فاکتور:', '📜 Previous Payment History:', '📜 سجل الدفعات السابقة:'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ...s.paymentLogs.map((pl) => Text('• $pl', style: const TextStyle(fontSize: 11.5, color: Colors.black54))),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                onPressed: () {
                  final rawAmt = double.tryParse(amtCtrl.text.trim()) ?? 0.0;
                  if (rawAmt <= 0) return;
                  final baseAmt = _fromInputToBaseRial(rawAmt);
                  final rem = s.remainingReceivableOMR;
                  final appliedAmt = baseAmt > rem ? rem : baseAmt;
                  final logNote = method.contains('چک')
                      ? '${_fmtDate(DateTime.now())}: ${_fmtMoneyWithUnit(appliedAmt)} (چک ${chequeNoCtrl.text.trim()} - سررسید ${chequeDueCtrl.text.trim()})'
                      : '${_fmtDate(DateTime.now())}: ${_fmtMoneyWithUnit(appliedAmt)} (نقدی/بانکی)';

                  setState(() {
                    s.paidAmountOMR += appliedAmt;
                    s.paymentLogs.add(logNote);
                    if (s.remainingReceivableOMR <= 0.001) {
                      s.paymentStatus = method.contains('چک') ? 'تسویه‌شده با چک PDC' : 'تسویه‌شده کامل';
                    } else {
                      s.paymentStatus = 'تسویه جزئی (اقساطی)';
                    }
                    _addAuditLog('دریافت مطالبات', 'دریافت ${_fmtMoneyWithUnit(appliedAmt)} از ${s.customerName} (${s.paymentStatus})', appliedAmt);
                  });
                  _saveLocalData();
                  if (_autoSyncOnEveryChange) _pushToCloud();
                  Navigator.pop(ctx);
                  _showMsg(_t('✅ مبلغ دریافتی ثبت و از مانده بدهی مشتری کسر شد.', '✅ Payment recorded & balance updated.', '✅ تم تسجيل الدفعة وتحديث رصيد العميل.'));
                },
                child: Text(_t('ثبت دریافت وجه', 'Save Payment', 'حفظ الدفعة')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: 'مسقط، سلطنت عمان');
    final vatinCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '1500');
    String tier = 'سوپرمارکت/هایپر';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
          textDirection: _activeDirection,
          child: AlertDialog(
            title: Text(_t('👤 تعریف پروفایل کامل مشتری و سقف اعتبار نسیه', '👤 Add Customer Profile & Credit Limit', '👤 إضافة ملف عميل وحد الائتمان')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: _t('نام مشتری / شرکت / فروشگاه *', 'Customer / Company Name *', 'اسم العميل / الشركة *'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tier,
                    items: [
                      DropdownMenuItem(value: 'عمده‌فروش (Wholesale)', child: Text(_t('تیپ ۱: عمده‌فروش / پخش', 'Tier 1: Wholesale', 'فئة ١: جملة'))),
                      DropdownMenuItem(value: 'سوپرمارکت/هایپر', child: Text(_t('تیپ ۲: سوپرمارکت / هایپرمارکت', 'Tier 2: Supermarket / Hyper', 'فئة ٢: سوبرماركت'))),
                      DropdownMenuItem(value: 'رستوران/فست‌فود', child: Text(_t('تیپ ۳: رستوران / فست‌فود / کترینگ', 'Tier 3: Restaurant / HORECA', 'فئة ٣: مطاعم'))),
                    ],
                    onChanged: (v) => setModalState(() => tier = v!),
                    decoration: InputDecoration(labelText: _t('تیپ قیمتی مشتری', 'Customer Price Tier', 'فئة تسعير العميل'), border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${_t("سقف مجاز خرید نسیه (Credit Limit)", "Max Credit Limit", "الحد الأقصى للائتمان")} ($_currUnit) *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: _t('تلفن و آدرس تحویل مشتری', 'Phone & Delivery Address', 'الهاتف وعنوان التسليم'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: vatinCtrl,
                    decoration: InputDecoration(
                      labelText: _t('کد ثبت مالیاتی عمان (VATIN - اختیاری)', 'Oman Tax VATIN (Optional)', 'الرقم الضريبي (اختياري)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_t('انصراف', 'Cancel', 'إلغاء'))),
              ElevatedButton(
                onPressed: () {
                  final c = nameCtrl.text.trim();
                  if (c.isEmpty) return;
                  final limitBase = _fromInputToBaseRial(double.tryParse(limitCtrl.text.trim()) ?? 1500.0);
                  setState(() {
                    if (!_customers.contains(c)) _customers.add(c);
                    _customerProfiles.removeWhere((p) => p.name == c);
                    _customerProfiles.add(CustomerProfile(
                      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                      name: c,
                      phoneAndAddress: phoneCtrl.text.trim(),
                      vatinCode: vatinCtrl.text.trim(),
                      priceTier: tier,
                      creditLimitOMR: limitBase,
                    ));
                    _saleCustomer = c;
                    _saleCustomerAddressCtrl.text = phoneCtrl.text.trim();
                  });
                  _saveLocalData();
                  if (_autoSyncOnEveryChange) _pushToCloud();
                  Navigator.pop(ctx);
                  _showMsg(_t('✅ پروفایل مشتری و سقف اعتبار نسیه ذخیره شد.', '✅ Customer profile & credit limit saved.', '✅ تم حفظ ملف العميل وحد الائتمان.'));
                },
                child: Text(_t('ثبت مشتری', 'Save Customer', 'حفظ العميل')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _autoDetectOmanVatRuleForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('گمرک') || c.contains('حمل') || c.contains('بسته‌بندی') || c.contains('سردخانه') || c.contains('اجاره') || c.contains('سوخت') || c.contains('تعمیر')) {
      _txVatClassRule = 'standard_5';
      _txHasVat = true;
      _txComptrollerApproved = true;
    } else if (c.contains('مواد غذایی پایه') || c.contains('صادرات')) {
      _txVatClassRule = 'zero_rated_0';
      _txHasVat = false;
      _txComptrollerApproved = true;
    } else if (c.contains('حقوق') || c.contains('دستمزد') || c.contains('کارمزد بانکی') || c.contains('شخصی')) {
      _txVatClassRule = 'exempt_non_claimable';
      _txHasVat = false;
      _txComptrollerApproved = false;
    }
  }

  String _vatRuleBadgeLabel(TransactionRecord t) {
    if (t.mode == TxMode.deposit) {
      return _t('ورودی تنخواه (غیرمشمول)', 'Petty Deposit (N/A)', 'إيداع عهدة');
    }
    if (t.hasVat5Percent || t.vatClassRule == 'standard_5') {
      return t.isComptrollerApprovedInputVat && t.taxInvoiceNo.trim().isNotEmpty
          ? _t('✅ مشمول ۵٪ VAT (تایید ذی‌حساب با فاکتور رسمی)', '✅ 5% Claimable VAT (Tax Invoice Verified)', '✅ خاضع لضريبة 5% (معتمد بفاتورة ضريبية)')
          : _t('⚠️ مشمول ۵٪ VAT (فاقد شماره فاکتور رسمی / نیازمند ممیزی)', '⚠️ 5% VAT (Missing Tax Invoice No)', '⚠️ ضريبة 5% (بانتظار رقم الفاتورة الضريبية)');
    }
    if (t.vatClassRule == 'zero_rated_0') {
      return _t('🟢 نرخ صفر مالیاتی عمان (۰٪ Zero-Rated)', '🟢 Zero-Rated (0% Oman OTA)', '🟢 خاضع لنسبة الصفر (0%)');
    }
    return _t('⚪ معاف / غیرقابل استرداد مالیاتی (Exempt)', '⚪ Exempt / Non-Claimable', '⚪ معفى / غير قابل للاسترداد');
  }

  void _saveExpenseOrDeposit() {
    if (_isBlockedByPeriodLock(_txDate)) return;
    final rawInputAmt = double.tryParse(_txAmountCtrl.text.trim());
    final title = _txTitleCtrl.text.trim();
    if (rawInputAmt == null || rawInputAmt <= 0 || title.isEmpty) {
      _showMsg(_t('لطفاً مبلغ ($_currUnit) و شرح را وارد کنید.', 'Please enter amount ($_currUnit) and description.', 'يرجى إدخال المبلغ ($_currUnit) والوصف.'));
      return;
    }

    final baseAmt = _fromInputToBaseRial(rawInputAmt);
    final isVat5 = _formMode == TxMode.expense && (_txHasVat || _txVatClassRule == 'standard_5');

    final rec = TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: _formMode,
      source: _formSource,
      amountOMR: double.parse(baseAmt.toStringAsFixed(4)),
      hasVat5Percent: isVat5,
      date: _txDate,
      topic: _selectedTopic,
      category: _formMode == TxMode.deposit ? 'دریافت تنخواه از شرکت' : _selectedCategory,
      title: title,
      note: _txNoteCtrl.text.trim(),
      createdBy: _currentUser?.displayName ?? 'مدیر',
      customValues: Map<String, String>.from(_selectedCustomValues),
      recordedExchangeRate: _usdExchangeRate,
      recordedCurrencyCode: _currency.name,
      taxInvoiceNo: _txTaxInvoiceNoCtrl.text.trim(),
      vatClassRule: _formMode == TxMode.deposit ? 'exempt_non_claimable' : _txVatClassRule,
      isComptrollerApprovedInputVat: isVat5 && _txComptrollerApproved,
    );

    setState(() {
      _transactions.insert(0, rec);
      _addAuditLog(
        'تنخواه، هزینه و ذی‌حسابی',
        '${rec.mode == TxMode.deposit ? "دریافت تنخواه" : "ثبت هزینه"}: ${rec.title} (${rec.category}) | VAT: ${_fmtMoneyWithUnit(rec.vatAmountOMR)}',
        rec.amountOMR,
      );
      _txAmountCtrl.clear();
      _txTitleCtrl.clear();
      _txNoteCtrl.clear();
      _txTaxInvoiceNoCtrl.clear();
      _txHasVat = false;
      _txVatClassRule = 'standard_5';
    });
    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showMsg(_t(
      '✅ سند با موفقیت ثبت شد و در «جدول فشرده هزینه‌ها» و «گزارش ذی‌حسابی مالیات VAT» قرار گرفت.',
      '✅ Saved to Compact Expense Table & Oman VAT Comptroller Report.',
      '✅ تم الحفظ في جدول المصاريف المدمج وتقرير ضريبة القيمة المضافة.',
    ));
  }

  Future<void> _printOfficialVatComptrollerReport() async {
    final dirStr = _lang == AppLang.en ? 'ltr' : 'rtl';
    final alignStr = _lang == AppLang.en ? 'left' : 'right';

    final double outputVatSales = _sales
        .where((s) => !s.isProformaQuote && s.hasVat5Percent)
        .fold(0.0, (sum, s) => sum + (s.isReturnDoc ? -s.vatAmountOMR.abs() : s.vatAmountOMR.abs()));
    final double taxableSalesNet = _sales
        .where((s) => !s.isProformaQuote && s.hasVat5Percent)
        .fold(0.0, (sum, s) => sum + s.totalRevenueOMR);

    final vatExpenses = _transactions.where((t) => t.mode == TxMode.expense && t.hasVat5Percent).toList();
    final double claimableInputVat = vatExpenses
        .where((t) => t.isComptrollerApprovedInputVat)
        .fold(0.0, (sum, t) => sum + t.vatAmountOMR);
    final double pendingUnverifiedInputVat = vatExpenses
        .where((t) => !t.isComptrollerApprovedInputVat)
        .fold(0.0, (sum, t) => sum + t.vatAmountOMR);
    final double nonVatExpensesTotal = _transactions
        .where((t) => t.mode == TxMode.expense && !t.hasVat5Percent)
        .fold(0.0, (sum, t) => sum + t.amountOMR);
    final double netVatPayableToOta = outputVatSales - claimableInputVat;

    final rowsHtml = <String>[];
    for (int i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.mode != TxMode.expense) continue;
      rowsHtml.add('''
        <tr>
          <td>${i + 1}</td>
          <td>${_fmtDate(t.date)}</td>
          <td><b>${t.title}</b></td>
          <td>${t.category}</td>
          <td>${t.taxInvoiceNo.isEmpty ? "—" : t.taxInvoiceNo}</td>
          <td>${_vatRuleBadgeLabel(t)}</td>
          <td>${_fmtOMR(t.netBeforeVatOMR)}</td>
          <td><b>${_fmtOMR(t.vatAmountOMR)}</b></td>
          <td><b>${_fmtOMR(t.amountOMR)}</b></td>
        </tr>
      ''');
    }

    final vatHeaderHtml = _buildOfficialPrintHeaderHtml(
      '⚖️ ${_t('گزارش نهایی ذی‌حسابی و اظهارنامه مالیات بر ارزش افزوده عمان (Oman OTA 5% VAT Return)', 'Official Oman Tax Authority (OTA) 5% VAT & Comptroller Audit Report', 'التقرير النهائي للمراقب المالي وإقرار ضريبة القيمة المضافة العمانية (5% VAT)')}',
      '<b>${_t('تاریخ صدور:', 'Date:', 'التاريخ:')}</b> ${_fmtDate(DateTime.now())}<br><b>${_t('واحد پول:', 'Currency:', 'العملة:')}</b> $_currUnit<br><b>CR No:</b> $kCompanyCrNo',
    );
    final vatFooterHtml = _buildOfficialPrintFooterHtml();

    final htmlDoc = '''<!DOCTYPE html>
<html lang="${_lang.name}" dir="$dirStr">
<head>
<meta charset="UTF-8">
<title>Oman VAT & Comptroller Report - CR $kCompanyCrNo</title>
<style>
  body { font-family: Tahoma, Arial, sans-serif; margin: 20px; color: #0f172a; }
  .box { border: 2px solid #1E3A5F; border-radius: 10px; padding: 18px; }
  .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 14px; }
  .kpi-card { background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; padding: 10px; font-size: 12px; }
  table { width: 100%; border-collapse: collapse; font-size: 11px; margin-top: 10px; }
  th, td { border: 1px solid #cbd5e1; padding: 5px 7px; text-align: $alignStr; }
  th { background: #1E3A5F; color: #fff; font-weight: bold; }
  tr:nth-child(even) { background: #f8fafc; }
  .signs { margin-top: 34px; display: flex; justify-content: space-around; text-align: center; font-size: 11.5px; }
  @media print { .no-print { display: none; } }
</style>
</head>
<body onload="window.print()">
  <div class="no-print" style="margin-bottom:12px;">
    <button onclick="window.print()" style="padding:8px 16px; background:#1E3A5F; color:#fff; border:none; border-radius:6px; cursor:pointer; font-weight:bold;">
      🖨️ ${_t('چاپ رسمی گزارش نهایی ذی‌حسابی و مالیات VAT عمان / PDF', 'Print Official Oman VAT & Comptroller Report / PDF', 'طباعة التقرير الضريبي النهائي / PDF')}
    </button>
  </div>
  <div class="box">
    $vatHeaderHtml
    <div class="kpi-grid">
      <div class="kpi-card"><b>۱. ${_t('مالیات فروش (Output VAT 5%):', 'Output VAT (Sales 5%):', 'ضريبة المبيعات 5%:')}</b><br><span style="font-size:14px; color:#b45309; font-weight:bold;">${_fmtMoneyWithUnit(outputVatSales)}</span><br><small>${_t('فروش مشمول:', 'Taxable Sales:', 'المبيعات الخاضعة:')} ${_fmtMoneyWithUnit(taxableSalesNet)}</small></div>
      <div class="kpi-card"><b>۲. ${_t('مالیات خرید قابل استرداد (Input VAT 5%):', 'Claimable Input VAT (5%):', 'ضريبة المشتريات القابلة للاسترداد:')}</b><br><span style="font-size:14px; color:#0f766e; font-weight:bold;">${_fmtMoneyWithUnit(claimableInputVat)}</span><br><small>${_t('در انتظار فاکتور رسمی:', 'Unverified VAT:', 'غير معتمد:')} ${_fmtMoneyWithUnit(pendingUnverifiedInputVat)}</small></div>
      <div class="kpi-card"><b>۳. ${_t('هزینه‌های معاف / نرخ صفر (۰٪):', 'Zero-Rated / Exempt Expenses:', 'المصاريف المعفاة / الصفرية:')}</b><br><span style="font-size:14px; color:#334155; font-weight:bold;">${_fmtMoneyWithUnit(nonVatExpensesTotal)}</span></div>
      <div class="kpi-card"><b>۴. ${_t('مانده خالص پرداختنی به مالیات عمان:', 'Net VAT Payable / (Refundable):', 'صافي الضريبة المستحقة للسلطنة:')}</b><br><span style="font-size:14px; color:#1E3A5F; font-weight:bold;">${_fmtMoneyWithUnit(netVatPayableToOta)}</span></div>
    </div>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>${_t('تاریخ', 'Date', 'التاريخ')}</th>
          <th>${_t('شرح هزینه / مدرک', 'Expense Description', 'بيان المصروف')}</th>
          <th>${_t('سرفصل', 'Category', 'الفئة')}</th>
          <th>${_t('شماره فاکتور مالیاتی (Tax Invoice)', 'Tax Invoice No', 'رقم الفاتورة الضريبية')}</th>
          <th>${_t('تشخیص ذی‌حساب و وضعیت VAT', 'Comptroller VAT Classification', 'التصنيف الضريبي')}</th>
          <th>${_t('مبلغ خالص', 'Net Amount', 'الصافي')} ($_currUnit)</th>
          <th>${_t('مالیات ۵٪ (VAT)', '5% VAT', 'الضريبة 5%')} ($_currUnit)</th>
          <th>${_t('جمع کل سند', 'Gross Total', 'الإجمالي')} ($_currUnit)</th>
        </tr>
      </thead>
      <tbody>
        ${rowsHtml.join('')}
      </tbody>
    </table>
    <div class="signs">
      <div>${_t('مهر و امضای ذی‌حساب و متخصص مالیات عمان', 'Oman Tax Specialist & Comptroller', 'توقيع أخصائي الضرائب والمراقب المالي')}<br><br>___________________</div>
      <div>${_t('امضای مدیر مالی (CFO)', 'Chief Financial Officer (CFO)', 'توقيع المدير المالي')}<br><br>___________________</div>
      <div>${_t('مهر و امضای مدیرعامل شرکت ارواد (CR: 1658937)', 'Managing Director — Arwad SPC', 'توقيع المدير العام لشركة أرواد')}<br><br>___________________</div>
    </div>
    $vatFooterHtml
  </div>
</body>
</html>''';

    final fileName = 'Arwad_Oman_VAT_Comptroller_Report_${_fmtDate(DateTime.now())}.html';
    try {
      final f = File('${Directory.current.path}/$fileName');
      await f.writeAsString(htmlDoc, encoding: utf8);
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', f.path]);
      }
      _showMsg(_t('✅ گزارش رسمی ذی‌حسابی و مالیات VAT عمان در فایل $fileName ذخیره و آماده چاپ شد.', '✅ Official Oman VAT report saved & opened.', '✅ تم حفظ تقرير ضريبة القيمة المضافة العمانية للطباعة.'));
    } catch (_) {
      Clipboard.setData(ClipboardData(
        text: 'گزارش ذی‌حسابی و مالیات بر ارزش افزوده عمان — $kCompanyTitleFa (CR: $kCompanyCrNo)
'
            'مالیات فروش (Output VAT 5%): ${_fmtMoneyWithUnit(outputVatSales)}
'
            'مالیات خرید قابل استرداد (Claimable Input VAT 5%): ${_fmtMoneyWithUnit(claimableInputVat)}
'
            'مانده خالص پرداختنی به سازمان مالیات عمان: ${_fmtMoneyWithUnit(netVatPayableToOta)}',
      ));
      _showMsg(_t('✅ خلاصه گزارش رسمی مالیات VAT در حافظه کپی شد.', '✅ VAT summary copied to clipboard.', '✅ تم نسخ ملخص الضريبة للحافظة.'));
    }
  }

  Widget _buildPettyCashAndExpensesTab(AppUserAccount u) {
    final canEdit = u.isSuperAdmin || u.canManagePettyCash;

    // فیلتر اسناد برای جدول فشرده
    final q = _txCompactSearchCtrl.text.trim().toLowerCase();
    final filteredTx = _transactions.where((t) {
      if (_txCompactVatFilter == 'vat_only' && !t.hasVat5Percent) return false;
      if (_txCompactVatFilter == 'non_vat' && t.hasVat5Percent) return false;
      if (q.isNotEmpty) {
        final hay = '${t.title} ${t.category} ${t.topic} ${t.taxInvoiceNo} ${t.createdBy}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    // محاسبات ذی‌حسابی و مالیات بر ارزش افزوده عمان (OTA 5% VAT)
    final double outputVatSales = _sales
        .where((s) => !s.isProformaQuote && s.hasVat5Percent)
        .fold(0.0, (sum, s) => sum + (s.isReturnDoc ? -s.vatAmountOMR.abs() : s.vatAmountOMR.abs()));
    final double claimableInputVat = _transactions
        .where((t) => t.mode == TxMode.expense && t.hasVat5Percent && t.isComptrollerApprovedInputVat)
        .fold(0.0, (sum, t) => sum + t.vatAmountOMR);
    final double unverifiedInputVat = _transactions
        .where((t) => t.mode == TxMode.expense && t.hasVat5Percent && !t.isComptrollerApprovedInputVat)
        .fold(0.0, (sum, t) => sum + t.vatAmountOMR);
    final double zeroOrExemptExpenses = _transactions
        .where((t) => t.mode == TxMode.expense && !t.hasVat5Percent)
        .fold(0.0, (sum, t) => sum + t.amountOMR);
    final double netVatPayable = outputVatSales - claimableInputVat;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // نوار زیرمنوی راست‌چین استاندارد مالی (تفکیک فرم ثبت، جدول فشرده با فونت ریز و گزارش ذی‌حسابی VAT)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(
                  '💳 مدیریت تنخواه، ثبت هزینه‌ها و سیستم ذی‌حسابی مالیاتی عمان (CR: $kCompanyCrNo)',
                  '💳 Petty Cash, Compact Expense Ledger & Oman VAT Comptroller (CR: $kCompanyCrNo)',
                  '💳 إدارة العهدة وجدول المصاريف المدمج والرقابة الضريبية العمانية (CR: $kCompanyCrNo)',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A5F)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  ChoiceChip(
                    label: Text(_t('➕ ۱. ثبت سند هزینه / تنخواه جدید', '➕ 1. Record Expense / Deposit', '➕ ١. تسجيل مصروف / عهدة')),
                    selected: _pettySubTab == 0,
                    onSelected: (_) => setState(() => _pettySubTab = 0),
                  ),
                  ChoiceChip(
                    label: Text(_t('📋 ۲. جدول استاندارد و فشرده هزینه‌ها (${_transactions.length})', '📋 2. Compact Expense Table (${_transactions.length})', '📋 ٢. جدول المصاريف المدمج (${_transactions.length})')),
                    selected: _pettySubTab == 1,
                    onSelected: (_) => setState(() => _pettySubTab = 1),
                  ),
                  ChoiceChip(
                    label: Text(_t('⚖️ ۳. ذی‌حسابی و گزارش نهایی مالیات VAT عمان', '⚖️ 3. Oman VAT & Comptroller Audit', '⚖️ ٣. الرقابة الضريبية وتقرير VAT النهائي')),
                    selected: _pettySubTab == 2,
                    onSelected: (_) => setState(() => _pettySubTab = 2),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // زیرتب ۰: فقط فرم تمیز ثبت هزینه و تشخیص هوشمند ذی‌حسابی (بدون شلوغی لیست هزینه‌ها در پایین صفحه)
        if (_pettySubTab == 0) ...[
          if (canEdit)
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
                              '➕ فرم ثبت هزینه روزانه، دریافت تنخواه و تشخیص خودکار مشمولیت VAT عمان',
                              '➕ Daily Expense / Petty Cash Entry & Automatic Oman VAT Detector',
                              '➕ نموذج تسجيل المصروفات والعهدة والتشخيص الضريبي التلقائي',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E3A5F)),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _pettySubTab = 1),
                          icon: const Icon(Icons.table_rows, size: 16),
                          label: Text(_t('مشاهده جدول فشرده (${_transactions.length})', 'View Compact Table (${_transactions.length})', 'عرض الجدول المدمج (${_transactions.length})'),
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(),
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
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: '${_t('مبلغ کل سند', 'Total Amount', 'المبلغ الإجمالي')} ($_currUnit) *',
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
                        onChanged: (v) {
                          setState(() {
                            _selectedCategory = v!;
                            _autoDetectOmanVatRuleForCategory(v);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: _t('سرفصل هزینه کرد (تشخیص خودکار قانون مالیات عمان با انتخاب سرفصل)', 'Expense Category (Auto Oman Tax Rule)', 'فئة المصروف (التشخيص الضريبي التلقائي)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // باکس تخصصی ذی‌حسابی و قوانین مالیات بر ارزش افزوده عمان (Oman Tax Authority - OTA)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E3A5F).withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t(
                                '⚖️ پنل ذی‌حسابی و تشخیص مشمولیت مالیات بر ارزش افزوده عمان (OTA 5% VAT):',
                                '⚖️ Oman Financial Comptroller & 5% VAT Eligibility Classification:',
                                '⚖️ تصنيف المراقب المالي وضريبة القيمة المضافة العمانية (5% VAT):',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E3A5F)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _txVatClassRule,
                              items: [
                                DropdownMenuItem(
                                  value: 'standard_5',
                                  child: Text(_t('۱. مشمول ۵٪ VAT استاندارد عمان (قابل کسر از مالیات فروش با فاکتور رسمی)', '1. Standard 5% Oman VAT (Claimable Input VAT)', '١. خاضع لضريبة 5% القياسية (قابل للاسترداد بفاتورة ضريبية)')),
                                ),
                                DropdownMenuItem(
                                  value: 'zero_rated_0',
                                  child: Text(_t('۲. مشمول نرخ صفر مالیاتی عمان ۰٪ (مواد غذایی پایه / صادرات)', '2. Zero-Rated 0% Oman OTA (Basic Food / Export)', '٢. خاضع لنسبة الصفر 0% (مواد غذائية أساسية / تصدير)')),
                                ),
                                DropdownMenuItem(
                                  value: 'exempt_non_claimable',
                                  child: Text(_t('۳. معاف از مالیات / فاقد فاکتور رسمی (غیرقابل استرداد از OTA)', '3. Exempt / Non-Claimable (No Tax Invoice)', '٣. معفى / بدون فاتورة ضريبية رسمية')),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _txVatClassRule = v!;
                                  _txHasVat = (v == 'standard_5');
                                });
                              },
                              decoration: InputDecoration(
                                labelText: _t('طبقه قانونی مالیات بر اساس ضوابط سازمان مالیات عمان (OTA)', 'Oman Tax Authority (OTA) VAT Rule', 'القاعدة الضريبية حسب القانون العماني'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            if (_txVatClassRule == 'standard_5') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _txTaxInvoiceNoCtrl,
                                      decoration: InputDecoration(
                                        labelText: _t('شماره فاکتور رسمی مالیاتی فروشنده (Tax Invoice / VATIN)', 'Supplier Tax Invoice No / VATIN', 'رقم الفاتورة الضريبية للمورد (VATIN)'),
                                        hintText: 'TAX-INV-2026-104',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        _t('تایید مدرک توسط ذی‌حساب جهت استرداد ۵٪', 'Comptroller Approved for 5% Claim', 'اعتماد المراقب المالي لاسترداد 5%'),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                      value: _txComptrollerApproved,
                                      onChanged: (v) => setState(() => _txComptrollerApproved = v ?? true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: _txTitleCtrl,
                      decoration: InputDecoration(
                        labelText: _t('عنوان / شرح دقیق هزینه یا دریافت تنخواه *', 'Expense / Deposit Title *', 'وصف المصروف أو العهدة *'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _saveExpenseOrDeposit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_t(
                        'ثبت نهایی سند (انتقال خودکار به جدول فشرده هزینه‌ها و گزارش VAT)',
                        'Save Transaction (Auto-Add to Compact Table & VAT Report)',
                        'حفظ السند (يضاف تلقائياً للجدول المدمج وتقرير الضريبة)',
                      )),
                    ),
                  ],
                ),
              ),
            ),
        ]

        // زیرتب ۱: جدول استاندارد، شیک، مرتب و فشرده هزینه‌ها با فونت ریز (بدون اشغال فضای اضافی)
        else if (_pettySubTab == 1) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _t(
                            '📋 جدول استاندارد و فشرده اسناد هزینه و تنخواه (با فونت ریز و اشغال حداقل فضا)',
                            '📋 Compact Standard Financial Expense & Petty Cash Table',
                            '📋 الجدول المالي المدمج والمنظم للمصاريف والعهدة',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A5F)),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          ChoiceChip(
                            label: Text(_t('همه (${_transactions.length})', 'All (${_transactions.length})', 'الكل (${_transactions.length})'), style: const TextStyle(fontSize: 11)),
                            selected: _txCompactVatFilter == 'all',
                            onSelected: (_) => setState(() => _txCompactVatFilter = 'all'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ChoiceChip(
                            label: Text(_t('فقط مشمول ۵٪ VAT', '5% VAT Only', 'الخاضع لضريبة 5% فقط'), style: const TextStyle(fontSize: 11)),
                            selected: _txCompactVatFilter == 'vat_only',
                            onSelected: (_) => setState(() => _txCompactVatFilter = 'vat_only'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ChoiceChip(
                            label: Text(_t('معاف / ۰٪', 'Exempt / 0%', 'معفى / 0%'), style: const TextStyle(fontSize: 11)),
                            selected: _txCompactVatFilter == 'non_vat',
                            onSelected: (_) => setState(() => _txCompactVatFilter = 'non_vat'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _txCompactSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      labelText: _t('جستجوی سریع در جدول فشرده (عنوان، سرفصل، شماره فاکتور مالیاتی...)', 'Quick search in compact table...', 'بحث سريع في الجدول المدمج...'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredTx.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _t('هیچ سند هزینه‌ای در این بخش ثبت نشده است.', 'No expense records found.', 'لا توجد سجلات مصاريف.'),
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 32,
                          dataRowHeight: 32,
                          columnSpacing: 14,
                          horizontalMargin: 10,
                          headingTextStyle: const TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 11),
                          dataTextStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 11),
                          columns: [
                            const DataColumn(label: Text('#')),
                            DataColumn(label: Text(_t('تاریخ', 'Date', 'التاريخ'))),
                            DataColumn(label: Text(_t('نوع سند', 'Type', 'النوع'))),
                            DataColumn(label: Text(_t('شرح هزینه / تنخواه', 'Title / Description', 'البيان'))),
                            DataColumn(label: Text(_t('سرفصل', 'Category', 'الفئة'))),
                            DataColumn(label: Text(_t('فاکتور مالیاتی', 'Tax Inv No', 'الفاتورة الضريبية'))),
                            DataColumn(label: Text(_t('وضعیت VAT عمان', 'Oman VAT Status', 'حالة الضريبة'))),
                            DataColumn(label: Text('${_t('مبلغ خالص', 'Net', 'الصافي')} ($_currUnit)')),
                            DataColumn(label: Text('${_t('۵٪ VAT', '5% VAT', 'ضريبة 5%')} ($_currUnit)')),
                            DataColumn(label: Text('${_t('جمع کل', 'Total', 'الإجمالي')} ($_currUnit)')),
                            DataColumn(label: Text(_t('کاربر', 'User', 'المستخدم'))),
                          ],
                          rows: List<DataRow>.generate(filteredTx.length, (idx) {
                            final t = filteredTx[idx];
                            final isDep = t.mode == TxMode.deposit;
                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                DataCell(Text(_fmtDate(t.date))),
                                DataCell(Text(
                                  isDep ? _t('ورودی تنخواه', 'Deposit', 'إيداع') : _t('هزینه', 'Expense', 'مصروف'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDep ? const Color(0xFF15803D) : const Color(0xFF1E3A5F),
                                  ),
                                )),
                                DataCell(Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(t.category)),
                                DataCell(Text(t.taxInvoiceNo.isEmpty ? '—' : t.taxInvoiceNo)),
                                DataCell(Text(
                                  t.hasVat5Percent ? '5% VAT (${t.isComptrollerApprovedInputVat ? "✓" : "!"})' : '0% / معاف',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.hasVat5Percent ? const Color(0xFF0F766E) : Colors.black54,
                                  ),
                                )),
                                DataCell(Text(_fmtOMR(t.netBeforeVatOMR))),
                                DataCell(Text(t.hasVat5Percent ? _fmtOMR(t.vatAmountOMR) : '0.000')),
                                DataCell(Text(
                                  '${isDep ? "+" : ""}${_fmtOMR(t.amountOMR)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text(t.createdBy)),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]

        // زیرتب ۲: سیستم ذی‌حسابی و گزارش نهایی مالیات بر ارزش افزوده عمان (Oman Tax Authority - OTA)
        else ...[
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
                            '⚖️ گزارش نهایی ذی‌حسابی و ممیزی مالیات بر ارزش افزوده عمان (OTA 5% VAT Return)',
                            '⚖️ Final Oman Tax Authority (OTA) 5% VAT & Comptroller Audit Report',
                            '⚖️ التقرير النهائي للمراقب المالي وإقرار ضريبة القيمة المضافة العمانية (5% VAT)',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A5F)),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _printOfficialVatComptrollerReport,
                        icon: const Icon(Icons.print, size: 16),
                        label: Text(_t('چاپ رسمی گزارش نهایی VAT (با سربرگ CR: $kCompanyCrNo)', 'Print Final VAT Report', 'طباعة تقرير الضريبة النهائي')),
                      ),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Container(
                        width: 245,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('۱. مالیات جمع‌آوری‌شده از فروش (Output VAT 5%)', '1. Output VAT Collected (Sales 5%)', '١. ضريبة المبيعات المحصلة (5%)'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_fmtMoneyWithUnit(outputVatSales),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ],
                        ),
                      ),
                      Container(
                        width: 245,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0F766E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('۲. مالیات خرید و هزینه قابل استرداد (Input VAT 5%)', '2. Claimable Input VAT (Approved 5%)', '٢. ضريبة المشتريات القابلة للاسترداد (5%)'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_fmtMoneyWithUnit(claimableInputVat),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          ],
                        ),
                      ),
                      Container(
                        width: 245,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF94A3B8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('۳. هزینه‌های نرخ صفر / معاف (۰٪) و بدون فاکتور', '3. Zero-Rated (0%) / Exempt Expenses', '٣. المصاريف الصفرية / المعفاة'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${_fmtMoneyWithUnit(zeroOrExemptExpenses)} | ⚠️ ${_fmtMoneyWithUnit(unverifiedInputVat)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                      Container(
                        width: 255,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E3A5F), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('۴. خالص مالیات پرداختنی / (طلب از مالیات عمان)', '4. Net VAT Payable / (Refundable OTA)', '٤. صافي الضريبة المستحقة للسلطنة'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_fmtMoneyWithUnit(netVatPayable),
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t(
                      '🔍 تفکیک مدارک و هزینه‌های مشمول ۵٪ مالیات بر ارزش افزوده عمان (تایید ذی‌حساب):',
                      '🔍 Breakdown of Documents & Expenses Eligible for 5% Oman VAT:',
                      '🔍 تفصيل المستندات والمصاريف الخاضعة لضريبة القيمة المضافة العمانية (5%):',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 30,
                        dataRowHeight: 32,
                        columnSpacing: 14,
                        headingTextStyle: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 11),
                        dataTextStyle: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                        columns: [
                          DataColumn(label: Text(_t('تاریخ', 'Date', 'التاريخ'))),
                          DataColumn(label: Text(_t('شرح هزینه / مدرک', 'Document / Expense', 'المستند / المصروف'))),
                          DataColumn(label: Text(_t('شماره فاکتور رسمی (Tax Inv)', 'Tax Invoice No', 'رقم الفاتورة الضريبية'))),
                          DataColumn(label: Text(_t('تشخیص ذی‌حساب', 'Comptroller Status', 'حالة الاعتماد'))),
                          DataColumn(label: Text('${_t('خالص قبل از VAT', 'Net Base', 'الصافي')} ($_currUnit)')),
                          DataColumn(label: Text('${_t('مبلغ ۵٪ VAT', '5% VAT Amount', 'مبلغ الضريبة 5%')} ($_currUnit)')),
                          DataColumn(label: Text('${_t('مبلغ کل مدرک', 'Gross Total', 'الإجمالي')} ($_currUnit)')),
                        ],
                        rows: _transactions
                            .where((t) => t.mode == TxMode.expense)
                            .map((t) => DataRow(
                                  cells: [
                                    DataCell(Text(_fmtDate(t.date))),
                                    DataCell(Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(t.taxInvoiceNo.isEmpty ? '—' : t.taxInvoiceNo)),
                                    DataCell(Text(_vatRuleBadgeLabel(t))),
                                    DataCell(Text(_fmtOMR(t.netBeforeVatOMR))),
                                    DataCell(Text(
                                      _fmtOMR(t.vatAmountOMR),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: t.hasVat5Percent ? const Color(0xFF0F766E) : Colors.black45,
                                      ),
                                    )),
                                    DataCell(Text(_fmtOMR(t.amountOMR), style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

    final extraPkgCost = _fromInputToBaseRial(double.tryParse(_prodExtraPkgCostCtrl.text.trim()) ?? 0.0);
    final rawCost = rawQty * rawItem.avgUnitCostOMR;
    final cartonCost = cartonQty * cartonItem.avgUnitCostOMR;
    final nylonCost = nylonQty * nylonItem.avgUnitCostOMR;
    final labelCost = labelQty * labelItem.avgUnitCostOMR;
    final totalBatchCost = rawCost + cartonCost + nylonCost + labelCost + extraPkgCost + tollFee + transport;

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
    if (_isBlockedByPeriodLock(DateTime.now())) return;
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
      if (_inbBatchNoCtrl.text.trim().isNotEmpty) item.batchNumber = _inbBatchNoCtrl.text.trim();
      if (_inbExpiryCtrl.text.trim().isNotEmpty) item.expiryDateStr = _inbExpiryCtrl.text.trim();
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
    if (_isBlockedByPeriodLock(DateTime.now())) return;
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
      if (_prodBatchNoCtrl.text.trim().isNotEmpty) finItem.batchNumber = _prodBatchNoCtrl.text.trim();
      if (_prodExpiryCtrl.text.trim().isNotEmpty) finItem.expiryDateStr = _prodExpiryCtrl.text.trim();
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inbBatchNoCtrl,
                          decoration: InputDecoration(
                            labelText: _t('شماره بچ / سری ساخت ورودی (Batch/Lot)', 'Batch / Lot Number', 'رقم التشغيلة / الدفعة'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inbExpiryCtrl,
                          decoration: InputDecoration(
                            labelText: _t('تاریخ انقضا سردخانه (YYYY-MM-DD)', 'Expiry Date (YYYY-MM-DD)', 'تاريخ الانتهاء (YYYY-MM-DD)'),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prodExtraPkgDescCtrl,
                          decoration: InputDecoration(
                            labelText: _t('سایر ملزومات بسته‌بندی اضافه (ظرف، فویل، شیرینگ، چسب...)', 'Extra Packaging Supplies (Foil, Tray, Shrink...)', 'مستلزمات تغليف إضافية (فويل، عبوة...)'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodExtraPkgCostCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: '${_t("هزینه ملزومات اضافه", "Extra Packaging Cost", "تكلفة التغليف الإضافي")} ($_currUnit)',
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
                          controller: _prodBatchNoCtrl,
                          decoration: InputDecoration(
                            labelText: _t('شماره بچ محصول نهایی (Batch No)', 'Finished Batch Number', 'رقم تشغيلة المنتج النهائي'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _prodExpiryCtrl,
                          decoration: InputDecoration(
                            labelText: _t('تاریخ انقضای محصول نهایی (FEFO)', 'Finished Expiry Date (YYYY-MM-DD)', 'تاريخ انتهاء الصلاحية'),
                            border: const OutlineInputBorder(),
                          ),
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
                            if (!slip.isStockPhysicallyDeducted)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB45309),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  setState(() {
                                    final matchedItems = _items.where((i) => i.id == slip.itemId).toList();
                                    if (matchedItems.isNotEmpty) {
                                      final itm = matchedItems.first;
                                      final totalOut = slip.qty + slip.freeBonusQty;
                                      itm.currentQty = (itm.currentQty - totalOut) > 0 ? (itm.currentQty - totalOut) : 0.0;
                                      itm.reservedQty = (itm.reservedQty - totalOut) > 0 ? (itm.reservedQty - totalOut) : 0.0;
                                    }
                                    slip.isStockPhysicallyDeducted = true;
                                    slip.deliveryStatus = 'تایید خروج فیزیکی انباردار - تحویل راننده شد';
                                    _addAuditLog('تایید خروج انباردار', 'تایید خروج فیزیکی حواله ${slip.slipNumber} از سردخانه توسط انباردار', slip.totalAmountBase);
                                  });
                                  _saveLocalData();
                                  if (_autoSyncOnEveryChange) _pushToCloud();
                                  _showMsg(_t('✅ خروج فیزیکی کالا توسط انباردار تایید شد و از موجودی فیزیکی سردخانه کسر گردید.', '✅ Physical dispatch approved by warehouse keeper.', '✅ تم تأكيد الإخراج الفعلي من المستودع.'));
                                },
                                icon: const Icon(Icons.warehouse, size: 16),
                                label: Text(_t('✅ تایید خروج فیزیکی توسط انباردار (کسر قطعی از سردخانه)', '✅ Approve Physical Dispatch (Deduct Stock)', '✅ تأكيد الإخراج الفعلي من المستودع')),
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
    final lowStockItems = list.where((i) => i.isLowStock).toList();
    final expiringItems = list.where((i) => i.isNearOrPastExpiry).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            if (lowStockItems.isNotEmpty || expiringItems.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lowStockItems.isNotEmpty)
                      Text(
                        '🔔 ${_t("هشدار نقطه سفارش (نیاز به شارژ موجودی):", "Low Stock Reorder Alert:", "تنبيه نقص المخزون:")} ${lowStockItems.map((e) => e.name).join("، ")}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    if (expiringItems.isNotEmpty)
                      Text(
                        '❄️ ${_t("هشدار تاریخ انقضای سردخانه (اولویت خروج FEFO):", "Cold-Chain Expiry Alert (FEFO):", "تنبيه قرب انتهاء الصلاحية (FEFO):")} ${expiringItems.map((e) => "${e.name} (${e.expiryDateStr})").join("، ")}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                  ],
                ),
              ),
            ],
            const Divider(),
            ...list.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (item.isLowStock)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(6)),
                          child: Text(_t('کمبود موجودی', 'Low Stock', 'نقص مخزون'), style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${_t('بهای واحد:', 'Avg Cost:', 'التكلفة:')} ${_fmtMoneyWithUnit(item.avgUnitCostOMR)}'
                    '${whType == WarehouseType.finishedGood ? ' | ${_t('فروش:', 'Price:', 'البيع:')} ${_fmtMoneyWithUnit(item.defaultSalePriceOMR)}' : ''}
'
                    '🏷️ Batch: ${item.batchNumber} | 📅 Exp (FEFO): ${item.expiryDateStr}'
                    '${item.reservedQty > 0 ? ' | ⏳ ${_t("رزرو حواله:", "Reserved:", "محجوز:")} ${_fmtQty(item.reservedQty)}' : ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_t('فیزیکی:', 'Physical:', 'فعلي:')} ${_fmtQty(item.currentQty)} ${item.unit}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12.5),
                      ),
                      if (item.reservedQty > 0)
                        Text(
                          '${_t('قابل فروش:', 'Available:', 'متاح:')} ${_fmtQty(item.availableQty)}',
                          style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // افزودن قلم فعلی به «سبد سفارش چندقلمی مشتری (Multi-Item Order Cart)»
  void _addCurrentLineToOrderCart() {
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final bonusQty = double.tryParse(_saleBonusQtyCtrl.text.trim()) ?? 0.0;
    final rawPrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final rawDisc = double.tryParse(_saleDiscountCtrl.text.trim()) ?? 0.0;
    if (_saleFinId == null || qty <= 0 || rawPrice < 0) {
      _showMsg(_t('لطفاً محصول، تعداد و قیمت واحد را وارد کنید.', 'Please enter product, quantity and unit price.', 'يرجى إدخال المنتج والكمية وسعر الوحدة.'));
      return;
    }
    final finItem = _items.firstWhere((e) => e.id == _saleFinId!);
    final totalPhysical = qty + bonusQty;
    if (!_isProformaMode && !_isSaleReturnMode && totalPhysical > finItem.availableQty + 0.0001) {
      _showMsg('❌ موجودی قابل فروش «${finItem.name}» (${_fmtQty(finItem.availableQty)}) کمتر از تعداد درخواستی به علاوه اشانتیون (${_fmtQty(totalPhysical)}) است!');
      return;
    }
    setState(() {
      _orderCart.add(OrderCartLine(
        itemId: finItem.id,
        itemName: finItem.name,
        unit: finItem.unit,
        unitWeightKg: finItem.unitWeightKg,
        qty: qty,
        freeBonusQty: bonusQty,
        unitSalePriceOMR: _fromInputToBaseRial(rawPrice),
        unitCogsOMR: finItem.avgUnitCostOMR,
        lineDiscountOMR: _fromInputToBaseRial(rawDisc),
        batchNumber: finItem.batchNumber,
        expiryDateStr: finItem.expiryDateStr,
      ));
      _saleQtyCtrl.clear();
      _saleBonusQtyCtrl.text = '0';
      _saleDiscountCtrl.text = '0';
    });
    _showMsg(_t('✅ به سبد سفارش چندقلمی اضافه شد. می‌توانید کالای بعدی را اضافه کنید یا فاکتور کل سبد را ثبت نمایید.', '✅ Added to multi-item order cart.', '✅ تمت الإضافة إلى سلة الطلب متعدد الأصناف.'));
  }

  // تبدیل یک‌کلیکی «پیش‌فاکتور رسمی (Proforma)» به سفارش قطعی فروش و صدور برگه خروج انبار
  void _convertProformaToConfirmedOrder(SaleProfitDoc proformaDoc) {
    final finItem = _items.firstWhere((e) => e.id == proformaDoc.finishedItemId, orElse: () => _finList.first);
    final totalNeeded = proformaDoc.qtySold + proformaDoc.freeBonusQty;
    if (totalNeeded > finItem.availableQty + 0.0001) {
      _showMsg('❌ موجودی انبار ۳ برای تبدیل این پیش‌فاکتور به فاکتور قطعی کافی نیست!');
      return;
    }
    late WarehouseExitSlip issuedSlip;
    setState(() {
      proformaDoc.isProformaQuote = false;
      proformaDoc.exitSlipNumber = 'EXIT-${1001 + _exitSlips.length}';
      proformaDoc.paymentStatus = _salePaymentStatus;
      if (_reserveStockUntilWhApproval) {
        finItem.reservedQty += totalNeeded;
      } else {
        finItem.currentQty -= totalNeeded;
      }
      issuedSlip = _issueWarehouseExitSlip(proformaDoc, finItem);
      _addAuditLog('تبدیل پیش‌فاکتور به فروش قطعی', 'تایید پیش‌فاکتور مشتری ${proformaDoc.customerName} و صدور برگه خروج ${issuedSlip.slipNumber}', proformaDoc.totalRevenueOMR);
    });
    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    _showExitSlipPreviewDialog(issuedSlip);
  }

  void _saveSaleOrReturnInvoice() {
    if (_isBlockedByPeriodLock(DateTime.now())) return;

    final deliv = _fromInputToBaseRial(double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0);
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;
    final customerName = _saleCustomer ?? 'مشتری بازار عمان';
    final custProfile = _getCustomerProfile(customerName);

    // اگر سبد سفارش چندقلمی پر باشد، کل اقلام سبد را در یک فاکتور و برگه خروج تجمیعی ثبت می‌کنیم:
    if (_orderCart.isNotEmpty) {
      final totalQty = _orderCart.fold(0.0, (s, l) => s + l.qty);
      final totalBonus = _orderCart.fold(0.0, (s, l) => s + l.freeBonusQty);
      final totalNetRev = _orderCart.fold(0.0, (s, l) => s + l.lineNetRevenueOMR);
      final totalDisc = _orderCart.fold(0.0, (s, l) => s + l.lineDiscountOMR);
      final totalCogsLines = _orderCart.fold(0.0, (s, l) => s + l.lineTotalCogsOMR);
      final avgPrice = totalQty > 0 ? (totalNetRev + totalDisc) / totalQty : 0.0;
      final avgCogs = (totalQty + totalBonus) > 0 ? totalCogsLines / (totalQty + totalBonus) : 0.0;
      final totalWithVat = _saleHasVat ? totalNetRev * 1.05 : totalNetRev;
      final isCash = _salePaymentStatus.contains('نقدی');

      // کنترل سقف اعتبار نسیه مشتری (Credit Limit Guard)
      if (!_isProformaMode && !_isSaleReturnMode && !isCash) {
        final currentDebt = _getCustomerCurrentDebtOMR(customerName);
        if (currentDebt + totalWithVat > custProfile.creditLimitOMR + 0.001) {
          _showMsg('❌ خطای سقف اعتبار نسیه: بدهی فعلی «$customerName» (${_fmtMoneyWithUnit(currentDebt)}) به علاوه این سفارش (${_fmtMoneyWithUnit(totalWithVat)}) از سقف اعتبار مجاز (${_fmtMoneyWithUnit(custProfile.creditLimitOMR)}) بیشتر است!');
          return;
        }
      }

      final summaryNames = _orderCart.map((l) => '${l.itemName} (${_fmtQty(l.qty)}${l.freeBonusQty > 0 ? "+${_fmtQty(l.freeBonusQty)} اشانتیون" : ""} ${l.unit})').join(' + ');
      final firstItem = _items.firstWhere((e) => e.id == _orderCart.first.itemId, orElse: () => _finList.first);
      final nextSlipNo = _isProformaMode ? 'PROFORMA-${101 + _sales.length}' : 'EXIT-${1001 + _exitSlips.length}';

      final doc = SaleProfitDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exitSlipNumber: nextSlipNo,
        date: DateTime.now(),
        finishedItemId: firstItem.id,
        finishedItemName: 'فاکتور چندقلمی (${_orderCart.length} قلم): $summaryNames',
        unit: 'بسته/قلم',
        qtySold: totalQty,
        freeBonusQty: totalBonus,
        unitSalePriceOMR: avgPrice,
        discountOMR: totalDisc,
        unitCogsOMR: avgCogs,
        deliveryExpenseOMR: deliv,
        hasVat5Percent: _saleHasVat,
        customerName: customerName,
        paymentStatus: _isProformaMode ? 'پیش‌فاکتور (Proforma)' : _salePaymentStatus,
        paidAmountOMR: (!_isProformaMode && isCash) ? totalWithVat : 0.0,
        partnerSplitDivisor: divisor < 1 ? 1 : divisor,
        isReturnDoc: false,
        isProformaQuote: _isProformaMode,
        lockedExchangeRate: _usdExchangeRate,
        multiItemsDescription: summaryNames,
        createdBy: _currentUser?.displayName ?? 'مدیر',
      );

      WarehouseExitSlip? issuedSlip;
      setState(() {
        if (!_isProformaMode) {
          for (final line in _orderCart) {
            final itm = _items.firstWhere((e) => e.id == line.itemId);
            if (_reserveStockUntilWhApproval) {
              itm.reservedQty += line.totalPhysicalQty;
            } else {
              itm.currentQty -= line.totalPhysicalQty;
            }
          }
          issuedSlip = _issueWarehouseExitSlip(doc, firstItem);
        }
        _sales.insert(0, doc);
        _orderCart.clear();
        _saleDeliveryCostCtrl.text = '0';
        _addAuditLog(
          _isProformaMode ? 'صدور پیش‌فاکتور چندقلمی' : 'فروش چندقلمی و برگه خروج',
          '$summaryNames به $customerName',
          totalWithVat,
        );
      });
      _saveLocalData();
      if (_autoSyncOnEveryChange) _pushToCloud();
      if (issuedSlip != null) {
        _showExitSlipPreviewDialog(issuedSlip!);
      } else {
        _showMsg(_t('✅ پیش‌فاکتور رسمی چندقلمی ثبت شد (بدون کسر از انبار).', '✅ Multi-item Proforma saved.', '✅ تم حفظ الفاتورة المبدئية.'));
      }
      return;
    }

    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final bonusQty = double.tryParse(_saleBonusQtyCtrl.text.trim()) ?? 0.0;
    final rawPrice = double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0;
    final rawDisc = double.tryParse(_saleDiscountCtrl.text.trim()) ?? 0.0;

    if (_saleFinId == null || qty <= 0 || rawPrice < 0) {
      _showMsg(_t('لطفاً محصول، تعداد و قیمت واحد را وارد کنید.', 'Please enter product, quantity and unit price.', 'يرجى إدخال المنتج والكمية وسعر الوحدة.'));
      return;
    }

    final price = _fromInputToBaseRial(rawPrice);
    final disc = _fromInputToBaseRial(rawDisc);
    final finItem = _items.firstWhere((e) => e.id == _saleFinId!);
    final totalPhysicalQty = qty + bonusQty;

    if (!_isProformaMode && !_isSaleReturnMode && totalPhysicalQty > finItem.availableQty + 0.0001) {
      _showMsg(
        '❌ ${_t('خطای کنترلی انبار ۳: موجودی قابل فروش', 'Warehouse 3 Stock Error: Available', 'خطأ مخزون المستودع ٣: المتوفر')} «${finItem.name}» (${_fmtQty(finItem.availableQty)} ${finItem.unit}) < (${_fmtQty(totalPhysicalQty)})!',
      );
      return;
    }

    final baseRevAfterDisc = ((qty * price) - disc) > 0 ? ((qty * price) - disc) : 0.0;
    final totalWithVat = _saleHasVat ? baseRevAfterDisc * 1.05 : baseRevAfterDisc;
    final isCash = _salePaymentStatus.contains('نقدی');

    // کنترل سقف اعتبار نسیه مشتری (Credit Limit Guard)
    if (!_isProformaMode && !_isSaleReturnMode && !isCash) {
      final currentDebt = _getCustomerCurrentDebtOMR(customerName);
      if (currentDebt + totalWithVat > custProfile.creditLimitOMR + 0.001) {
        _showMsg(
          '❌ خطای سقف اعتبار نسیه مشتری: بدهی فعلی «$customerName» (${_fmtMoneyWithUnit(currentDebt)}) به علاوه این فاکتور (${_fmtMoneyWithUnit(totalWithVat)}) از سقف اعتبار مجاز او (${_fmtMoneyWithUnit(custProfile.creditLimitOMR)}) بیشتر است!',
        );
        return;
      }
    }

    final nextSlipNo = _isProformaMode ? 'PROFORMA-${101 + _sales.length}' : 'EXIT-${1001 + _exitSlips.length}';

    final doc = SaleProfitDoc(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exitSlipNumber: nextSlipNo,
      date: DateTime.now(),
      finishedItemId: finItem.id,
      finishedItemName: finItem.name,
      unit: finItem.unit,
      qtySold: qty,
      freeBonusQty: bonusQty,
      unitSalePriceOMR: price,
      discountOMR: disc,
      unitCogsOMR: finItem.avgUnitCostOMR,
      deliveryExpenseOMR: deliv,
      hasVat5Percent: _saleHasVat,
      customerName: customerName,
      paymentStatus: _isProformaMode
          ? 'پیش‌فاکتور رسمی (Proforma)'
          : (_isSaleReturnMode ? 'مرجوعی / برگشت از فروش' : _salePaymentStatus),
      paidAmountOMR: (!_isProformaMode && (_isSaleReturnMode || isCash)) ? totalWithVat : 0.0,
      partnerSplitDivisor: divisor < 1 ? 1 : divisor,
      isReturnDoc: _isSaleReturnMode,
      isProformaQuote: _isProformaMode,
      lockedExchangeRate: _usdExchangeRate,
      createdBy: _currentUser?.displayName ?? 'مدیر',
    );

    WarehouseExitSlip? issuedSlip;

    setState(() {
      if (!_isProformaMode) {
        if (_isSaleReturnMode) {
          finItem.currentQty += totalPhysicalQty;
        } else if (_reserveStockUntilWhApproval) {
          finItem.reservedQty += totalPhysicalQty;
        } else {
          finItem.currentQty -= totalPhysicalQty;
        }
        issuedSlip = _issueWarehouseExitSlip(doc, finItem);
      }
      _sales.insert(0, doc);

      _addAuditLog(
        _isProformaMode
            ? 'صدور پیش‌فاکتور'
            : (_isSaleReturnMode ? 'برگشت از فروش' : 'سفارش فروش و صدور برگه خروج'),
        '${_fmtQty(qty)} ${finItem.unit} ${finItem.name}${bonusQty > 0 ? " (+${_fmtQty(bonusQty)} اشانتیون)" : ""} به ${doc.customerName}',
        totalWithVat.abs(),
      );
      _saleQtyCtrl.clear();
      _saleBonusQtyCtrl.text = '0';
      _saleDiscountCtrl.text = '0';
      _saleDeliveryCostCtrl.text = '0';
      _isSaleReturnMode = false;
    });

    _saveLocalData();
    if (_autoSyncOnEveryChange) _pushToCloud();
    if (issuedSlip != null) {
      _showExitSlipPreviewDialog(issuedSlip!);
    } else {
      _showMsg(_t('✅ پیش‌فاکتور رسمی بدون کسر از انبار صادر شد.', '✅ Proforma invoice saved without deducting stock.', '✅ تم إصدار الفاتورة المبدئية بدون خصم المخزون.'));
    }
  }

  Widget _buildSalesProfitAndPartnerTab(AppUserAccount u) {
    final finItem = _finList.firstWhere((e) => e.id == _saleFinId, orElse: () => _finList.first);
    final qty = double.tryParse(_saleQtyCtrl.text.trim()) ?? 0.0;
    final bonusQty = double.tryParse(_saleBonusQtyCtrl.text.trim()) ?? 0.0;
    final salePriceBase = _fromInputToBaseRial(double.tryParse(_salePriceCtrl.text.trim()) ?? 0.0);
    final discBase = _fromInputToBaseRial(double.tryParse(_saleDiscountCtrl.text.trim()) ?? 0.0);
    final delivCostBase = _fromInputToBaseRial(double.tryParse(_saleDeliveryCostCtrl.text.trim()) ?? 0.0);
    final divisor = _salePartnerDivisor == 0
        ? (int.tryParse(_customDivisorCtrl.text.trim()) ?? 1)
        : _salePartnerDivisor;
    final safeDivisor = divisor < 1 ? 1 : divisor;

    final totalRev = ((qty * salePriceBase) - discBase) > 0 ? ((qty * salePriceBase) - discBase) : 0.0;
    final totalCogs = ((qty + bonusQty) * finItem.avgUnitCostOMR) + delivCostBase;
    final netProfit = totalRev - totalCogs;
    final marginPct = totalRev > 0 ? (netProfit / totalRev) * 100.0 : 0.0;
    final myShare = netProfit / safeDivisor;

    final activeCustName = _saleCustomer ?? (_customers.isNotEmpty ? _customers.first : 'مشتری بازار عمان');
    final activeCustProfile = _getCustomerProfile(activeCustName);
    final activeCustDebt = _getCustomerCurrentDebtOMR(activeCustName);
    final activeCustRemCredit = (activeCustProfile.creditLimitOMR - activeCustDebt) > 0
        ? (activeCustProfile.creditLimitOMR - activeCustDebt)
        : 0.0;

    final unpaidSales = _sales.where((s) => s.remainingReceivableOMR > 0.0005).toList();
    final proformaQuotes = _sales.where((s) => s.isProformaQuote).toList();

    // محاسبه سن بدهی مشتریان (Aging Report: 0-30, 31-60, >60 Days)
    final double aging0to30 = unpaidSales.where((s) => s.daysOverdue <= 30).fold(0.0, (sum, s) => sum + s.remainingReceivableOMR);
    final double aging31to60 = unpaidSales.where((s) => s.daysOverdue > 30 && s.daysOverdue <= 60).fold(0.0, (sum, s) => sum + s.remainingReceivableOMR);
    final double agingOver60 = unpaidSales.where((s) => s.daysOverdue > 60).fold(0.0, (sum, s) => sum + s.remainingReceivableOMR);

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
                            label: Text(_t('🛒 سفارش قطعی + برگه خروج انبار', '🛒 Confirmed Order + Exit Slip', '🛒 طلب مؤكد + سند إخراج')),
                            selected: !_isSaleReturnMode && !_isProformaMode,
                            onSelected: (_) => setState(() {
                              _isSaleReturnMode = false;
                              _isProformaMode = false;
                            }),
                          ),
                          ChoiceChip(
                            label: Text(_t('📄 صدور پیش‌فاکتور رسمی (Proforma)', '📄 Proforma Invoice (Quote)', '📄 فاتورة مبدئية (عرض سعر)')),
                            selected: _isProformaMode,
                            onSelected: (_) => setState(() {
                              _isProformaMode = true;
                              _isSaleReturnMode = false;
                            }),
                          ),
                          ChoiceChip(
                            label: Text(_t('↩️ برگشت از فروش (مرجوعی)', '↩️ Sales Return', '↩️ مرتجع مبيعات')),
                            selected: _isSaleReturnMode,
                            onSelected: (_) => setState(() {
                              _isSaleReturnMode = true;
                              _isProformaMode = false;
                            }),
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    '🏷️ ${_t("تیپ قیمتی:", "Price Tier:", "فئة السعر:")} ${activeCustProfile.priceTier} | '
                    '💳 ${_t("سقف اعتبار نسیه:", "Credit Limit:", "حد الائتمان:")} ${_fmtMoneyWithUnit(activeCustProfile.creditLimitOMR)} | '
                    '💵 ${_t("بدهی فعلی:", "Current Debt:", "المديونية الحالية:")} ${_fmtMoneyWithUnit(activeCustDebt)} | '
                    '✅ ${_t("اعتبار آزاد:", "Available Credit:", "الائتمان المتاح:")} ${_fmtMoneyWithUnit(activeCustRemCredit)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
                        controller: _saleDiscountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: '${_t("تخفیف فاکتور (Discount)", "Invoice Discount", "خصم الفاتورة")} ($_currUnit)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _saleBonusQtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: _t('تعداد اشانتیون / نمونه رایگان (Bonus Qty)', 'Free Bonus / Sample Qty', 'كمية مجانية / عينة'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addCurrentLineToOrderCart,
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: Text(_t(
                    '➕ افزودن این محصول به «سبد سفارش چندقلمی مشتری» (جهت صدور یک فاکتور برای چند کالا)',
                    '➕ Add Item to Multi-Product Order Cart',
                    '➕ إضافة هذا الصنف إلى سلة الطلب متعدد الأصناف',
                  )),
                ),
                if (_orderCart.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0F766E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🛒 ${_t("اقلام موجود در سبد سفارش چندقلمی", "Multi-Item Order Cart", "سلة الطلب متعدد الأصناف")} (${_orderCart.length}):',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _orderCart.clear()),
                              child: Text(_t('پاک کردن سبد', 'Clear Cart', 'إفراغ السلة'), style: const TextStyle(color: Colors.red, fontSize: 11.5)),
                            ),
                          ],
                        ),
                        ..._orderCart.map((line) => Text(
                              '• ${line.itemName}: ${_fmtQty(line.qty)} ${line.unit}'
                              '${line.freeBonusQty > 0 ? " (+${_fmtQty(line.freeBonusQty)} اشانتیون)" : ""}'
                              ' — ${_fmtMoneyWithUnit(line.lineNetRevenueOMR)}',
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                ],
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
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(
                    '⏳ فرآیند دو مرحله‌ای انبار: رزرو کالا در انبار ۳ و کسر قطعی فقط پس از «تایید خروج فیزیکی توسط انباردار»',
                    '⏳ Two-Step Dispatch: Reserve stock now & deduct only after Warehouse Keeper physical approval',
                    '⏳ حجز البضاعة وخصمها فقط بعد تأكيد أمين المستودع',
                  )),
                  value: _reserveStockUntilWhApproval,
                  onChanged: (v) => setState(() => _reserveStockUntilWhApproval = v ?? false),
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

        if (proformaQuotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📄 ${_t("پیش‌فاکتورهای رسمی صادرشده (در انتظار تایید مشتری - بدون کسر از انبار):", "Pending Proforma Quotations (Not Deducted from Stock):", "الفواتير المبدئية الصادرة (بانتظار تأكيد العميل):")}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                  const Divider(),
                  ...proformaQuotes.map((pf) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('📄 ${pf.exitSlipNumber} — 👤 ${pf.customerName} (${pf.finishedItemName})'),
                        subtitle: Text('${_t("مبلغ پیش‌فاکتور:", "Quote Total:", "إجمالي العرض:")} ${_fmtMoneyWithUnit(pf.totalInvoiceWithVatOMR)} | 📅 ${_fmtDate(pf.date)}'),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
                          onPressed: () => _convertProformaToConfirmedOrder(pf),
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(_t('تبدیل به فاکتور قطعی + برگه خروج', 'Convert to Order & Exit Slip', 'تحويل لطلب مؤكد وسند إخراج')),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],

        if (unpaidSales.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💵 ${_t('مطالبات نسیه از مشتریان و گزارش سن بدهی (Aging Report)', 'Customer Accounts Receivable & Aging Report', 'ذمم العملاء وتقرير أعمار الديون')} (${_fmtMoneyWithUnit(_totalUnpaidReceivablesOMR)}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      '📊 ${_t("تحلیل سن مطالبات:", "Receivables Aging:", "أعمار الديون:")} '
                      '🟢 0-30 ${_t("روز:", "Days:", "يوم:")} ${_fmtMoneyWithUnit(aging0to30)}  |  '
                      '🟠 31-60 ${_t("روز:", "Days:", "يوم:")} ${_fmtMoneyWithUnit(aging31to60)}  |  '
                      '🔴 +60 ${_t("روز (معوق):", "Days (Overdue):", "يوم (متأخر):")} ${_fmtMoneyWithUnit(agingOver60)}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  ...unpaidSales.map((s) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('👤 ${s.customerName} — ${s.finishedItemName} (${s.exitSlipNumber})'),
                        subtitle: Text(
                          '${_t('مانده بدهی:', 'Remaining:', 'المتبقي:')} ${_fmtMoneyWithUnit(s.remainingReceivableOMR)} '
                          '(${_t('پرداخت‌شده:', 'Paid:', 'المدفوع:')} ${_fmtMoneyWithUnit(s.paidAmountOMR)} | ⏱️ ${s.daysOverdue} ${_t('روز', 'days', 'يوم')})',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showPartialReceivableSettlementModal(s),
                          child: Text(_t('ثبت دریافت (کامل / قسط / چک PDC)', 'Record Payment / PDC', 'تسجيل دفعة / شيك')),
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

    final repHeaderHtml = _buildOfficialPrintHeaderHtml(
      repTitle,
      '<b>${_t('تاریخ گزارش:', 'Report Date:', 'تاريخ التقرير:')}</b> ${_fmtDate(DateTime.now())}<br><b>${_t('واحد پول گزارش:', 'Currency:', 'العملة:')}</b> $_currUnit<br><b>${_t('کاربر صادرکننده:', 'Prepared By:', 'المستخدم:')}</b> ${_currentUser?.displayName ?? 'Admin'}',
    );
    final repFooterHtml = _buildOfficialPrintFooterHtml();

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
  $repHeaderHtml
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
    <div>${_t('امضای ذی‌حساب و ممیز مالیاتی عمان', 'Financial Comptroller & Tax Auditor', 'توقيع المراقب المالي والضريبي')}<br><br>___________________</div>
    <div>${_t('امضای مدیریت ارشد / شرکا', 'Executive / Partners Approval', 'توقيع الإدارة العليا / الشركاء')}<br><br>___________________</div>
  </div>
  $repFooterHtml
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📊 ${_t('جدول شسته‌رفته و مرتب گزارش جامع مالی و عملیاتی', 'Clean Structured Financial Report Table', 'جدول التقرير المالي المنظم')} (${dynamicRows.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A5F)),
                      ),
                      Text(
                        'CR: $kCompanyCrNo | $_currUnit',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (dynamicRows.isEmpty)
                    Text(_t('هیچ داده‌ای با فیلترهای انتخابی یافت نشد.', 'No matching records found.', 'لا توجد بيانات مطابقة.'))
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 32,
                          dataRowHeight: 32,
                          columnSpacing: 14,
                          horizontalMargin: 10,
                          headingTextStyle: const TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 11),
                          dataTextStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 11),
                          columns: [
                            const DataColumn(label: Text('#')),
                            if (_colDate) DataColumn(label: Text(_t('تاریخ', 'Date', 'التاريخ'))),
                            if (_colType) DataColumn(label: Text(_t('نوع سند', 'Type', 'النوع'))),
                            if (_colTitle) DataColumn(label: Text(_t('شرح / کالا', 'Item / Title', 'الصنف'))),
                            if (_colParty) DataColumn(label: Text(_t('مشتری / مرکز', 'Party', 'العميل'))),
                            if (_colCategory) DataColumn(label: Text(_t('سرفصل / انبار', 'Category', 'الفئة'))),
                            if (_colQty) DataColumn(label: Text(_t('مقدار', 'Qty', 'الكمية'))),
                            if (_colUnitPrice) DataColumn(label: Text('${_t('فی واحد', 'Unit Price', 'سعر الوحدة')} ($_currUnit)')),
                            if (_colTotalAmount) DataColumn(label: Text('${_t('مبلغ کل', 'Total', 'الإجمالي')} ($_currUnit)')),
                            if (_colCogsAndProfit) DataColumn(label: Text('${_t('سود خالص', 'Profit', 'الربح')} ($_currUnit)')),
                            if (_colUserAndStatus) DataColumn(label: Text(_t('وضعیت / کاربر', 'Status', 'الحالة'))),
                          ],
                          rows: List<DataRow>.generate(dynamicRows.take(100).length, (idx) {
                            final r = dynamicRows[idx];
                            return DataRow(
                              cells: [
                                DataCell(Text('${idx + 1}')),
                                if (_colDate) DataCell(Text(_fmtDate(r.date))),
                                if (_colType) DataCell(Text(r.docType, style: const TextStyle(fontWeight: FontWeight.w600))),
                                if (_colTitle) DataCell(Text(r.titleOrItem, style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (_colParty) DataCell(Text(r.partyOrTopic)),
                                if (_colCategory) DataCell(Text(r.categoryOrWh)),
                                if (_colQty) DataCell(Text('${_fmtQty(r.qty)} ${r.unit}')),
                                if (_colUnitPrice) DataCell(Text(_fmtOMR(r.unitPriceOrCostOMR))),
                                if (_colTotalAmount) DataCell(Text(_fmtOMR(r.totalAmountOMR), style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (_colCogsAndProfit)
                                  DataCell(Text(
                                    _fmtOMR(r.profitOMR),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: r.profitOMR >= 0 ? const Color(0xFF15803D) : Colors.red[700],
                                    ),
                                  )),
                                if (_colUserAndStatus) DataCell(Text(r.statusOrUser)),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
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
                  const Divider(height: 24),
                  Text(
                    _t(
                      '🔒 قفل بستن دوره مالی و تسویه حساب شرکا (جلوگیری از ثبت یا دستکاری اسناد در دوره‌های تسویه‌شده قبلی):',
                      '🔒 Accounting Period Closing Lock Date (Prevent Backdated Entries):',
                      '🔒 قفل إغلاق الفترة المالية (منع إدخال مستندات بتاريخ سابق):',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _periodLockDateCtrl,
                          decoration: InputDecoration(
                            labelText: _t('تاریخ قفل دوره مالی (YYYY-MM-DD)', 'Period Lock Date (YYYY-MM-DD)', 'تاريخ إغلاق الفترة (YYYY-MM-DD)'),
                            hintText: '2026-09-30',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB45309), foregroundColor: Colors.white),
                        onPressed: () {
                          final parsed = DateTime.tryParse(_periodLockDateCtrl.text.trim());
                          setState(() => _periodLockDate = parsed);
                          _addAuditLog('قفل دوره مالی', parsed != null ? 'قفل شدن دوره مالی تا تاریخ ${_fmtDate(parsed)}' : 'باز شدن قفل دوره مالی', 0);
                          _saveLocalData();
                          if (_autoSyncOnEveryChange) _pushToCloud();
                          _showMsg(parsed != null
                              ? _t('✅ دوره مالی تا تاریخ ${_fmtDate(parsed)} قفل شد.', '✅ Period locked up to ${_fmtDate(parsed)}.', '✅ تم إغلاق الفترة المالية.')
                              : _t('🔓 قفل دوره مالی برداشته شد.', '🔓 Period lock cleared.', '🔓 تم إلغاء قفل الفترة.'));
                        },
                        child: Text(_t('اعمال قفل دوره', 'Apply Lock', 'تطبيق القفل')),
                      ),
                    ],
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

  // دیالوگ بازیابی اضطراری رمز ادمین با «پسورد مادر (Master Recovery Password)»
  void _showEmergencyMasterRecoveryDialog() {
    final masterCtrl = TextEditingController();
    final newAdminUserCtrl = TextEditingController(
      text: _users.where((u) => u.isSuperAdmin).isNotEmpty
          ? _users.firstWhere((u) => u.isSuperAdmin).username
          : 'admin',
    );
    final newAdminPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _activeDirection,
        child: AlertDialog(
          title: Text(_t(
            '🆘 بازیابی اضطراری حساب ادمین با «پسورد مادر»',
            '🆘 Emergency Admin Recovery via Master Password',
            '🆘 استعادة حساب المدير العام بكلمة المرور الأم',
          )),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t(
                    'اگر رمز عبور ادمین را فراموش کرده‌اید، «پسورد مادر (شاه‌کلید)» خود را وارد کنید تا رمز جدیدی برای ادمین تنظیم شده و وارد برنامه شوید:',
                    'Enter your Master Recovery Key to reset the Super Admin password and log in immediately:',
                    'أدخل كلمة المرور الأم لإعادة تعيين كلمة مرور المدير العام والدخول فوراً:',
                  ),
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: masterCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _t('پسورد مادر / شاه‌کلید اضطراری (Master Key) *', 'Master Recovery Key *', 'كلمة المرور الأم *'),
                    prefixIcon: const Icon(Icons.key),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newAdminUserCtrl,
                  decoration: InputDecoration(
                    labelText: _t('نام کاربری ادمین (Username) *', 'Admin Username *', 'اسم مستخدم المدير *'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newAdminPassCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _t('رمز عبور جدید برای ادمین (حداقل ۴ کاراکتر) *', 'New Admin Password (min 4 chars) *', 'كلمة المرور الجديدة للمدير *'),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final enteredMaster = masterCtrl.text.trim();
                final newU = newAdminUserCtrl.text.trim();
                final newP = newAdminPassCtrl.text.trim();

                if (enteredMaster != kBuiltInFactoryMasterKey && enteredMaster != _customMasterRecoveryKey) {
                  _showMsg(_t(
                    '❌ پسورد مادر واردشده اشتباه است!',
                    '❌ Invalid Master Recovery Key!',
                    '❌ كلمة المرور الأم غير صحيحة!',
                  ));
                  return;
                }
                if (newU.isEmpty || newP.length < 4) {
                  _showMsg(_t(
                    'لطفاً نام کاربری و رمز عبور جدید (حداقل ۴ کاراکتر) را وارد کنید.',
                    'Please enter username and new password (min 4 chars).',
                    'يرجى إدخال اسم المستخدم وكلمة المرور الجديدة.',
                  ));
                  return;
                }

                AppUserAccount adminAcc;
                final existingAdmins = _users.where((u) => u.isSuperAdmin).toList();
                if (existingAdmins.isNotEmpty) {
                  adminAcc = existingAdmins.first;
                  adminAcc.username = newU;
                  adminAcc.password = newP;
                } else {
                  adminAcc = AppUserAccount(
                    id: 'usr_admin',
                    username: newU,
                    password: newP,
                    displayName: 'مدیر ارشد (ادمین)',
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
                  _users.insert(0, adminAcc);
                }

                setState(() {
                  _currentUser = adminAcc;
                  _selectedIndex = 0;
                });
                _addAuditLog('بازیابی رمز ادمین', 'بازنشانی رمز ادمین اصلی با استفاده از پسورد مادر (Master Key)', 0);
                _saveLocalData();
                if (_autoSyncOnEveryChange) _pushToCloud();
                Navigator.pop(ctx);
                _showMsg(_t(
                  '✅ رمز ادمین با موفقیت بازنشانی شد و وارد سامانه شدید.',
                  '✅ Admin password reset successfully & logged in.',
                  '✅ تمت إعادة تعيين كلمة مرور المدير والدخول بنجاح.',
                ));
              },
              icon: const Icon(Icons.lock_open, size: 18),
              label: Text(_t('بازنشانی رمز ادمین و ورود فوری', 'Reset Password & Login', 'إعادة التعيين والدخول')),
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            '🔑 تنظیم «پسورد مادر اضطراری (Master Recovery Key)» ویژه بازگردانی حساب ادمین:',
                            '🔑 Emergency Master Recovery Password Configuration (Super Admin Only):',
                            '🔑 إعداد «كلمة المرور الأم الطارئة» لاستعادة حساب المدير العام:',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _masterKeySettingCtrl,
                                decoration: InputDecoration(
                                  labelText: _t('پسورد مادر اختصاصی شما', 'Your Custom Master Recovery Key', 'كلمة المرور الأم الخاصة بك'),
                                  helperText: _t(
                                    'شاه‌کلید پیش‌فرض کارخانه: OMAN-MASTER-2026 (می‌توانید شاه‌کلید اختصاصی خود را هم تنظیم کنید)',
                                    'Factory default Master Key: OMAN-MASTER-2026',
                                    'كلمة المرور الأم الافتراضية: OMAN-MASTER-2026',
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB45309),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                final mk = _masterKeySettingCtrl.text.trim();
                                if (mk.length < 6) {
                                  _showMsg(_t('پسورد مادر باید حداقل ۶ کاراکتر باشد.', 'Master Key must be at least 6 chars.', 'يجب أن تكون 6 أحرف على الأقل.'));
                                  return;
                                }
                                setState(() => _customMasterRecoveryKey = mk);
                                _addAuditLog('امنیت', 'به‌روزرسانی پسورد مادر اضطراری (Master Key) توسط ادمین', 0);
                                _saveLocalData();
                                if (_autoSyncOnEveryChange) _pushToCloud();
                                _showMsg(_t('✅ پسورد مادر اضطراری ذخیره شد.', '✅ Master Recovery Key saved.', '✅ تم حفظ كلمة المرور الأم.'));
                              },
                              child: Text(_t('ذخیره پسورد مادر', 'Save Master Key', 'حفظ')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildHelpAndManualTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildArwadLogoWidget(height: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _companyOfficialTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1E3A5F)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _companyOfficialSubHeader,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _designerCreditText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  _t(
                    '📘 راهنمای گام‌به‌گام استفاده از نرم‌افزار مالی، انبار، سفارشات و ذی‌حسابی مالیاتی شرکت ارواد (Help)',
                    '📘 Comprehensive User Guide — Arwad International Food Industries ERP (CR: $kCompanyCrNo)',
                    '📘 الدليل الشامل لاستخدام النظام المالي والمستودعات لشركة أرواد العالمية للصناعات الغذائية',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 10),
                _buildHelpSectionTile(
                  _t('۱. راهنمای ورود اولیه، تنظیم آدرس دیتابیس سرور و پسورد مادر', '1. Initial Database Setup, User Login & Emergency Master Key', '١. الإعداد الأولي لقاعدة البيانات وتسجيل الدخول وكلمة المرور الأم'),
                  _t(
                    '• در اولین اجرای برنامه روی هر سیستم، ابتدا آدرس سرور دیتابیس را وارد کنید یا گزینه «دیتابیس داخلی دستگاه» را بزنید.
'
                    '• اگر رمز ادمین را فراموش کردید، در صفحه ورود روی دکمه «بازیابی با پسورد مادر» بزنید و شاه‌کلید اضطراری (OMAN-MASTER-2026) یا پسورد مادر اختصاصی خود را وارد نمایید.',
                    '• On first run, configure the central database URL or initialize local storage.
'
                    '• If the Admin password is forgotten, use the Emergency Master Key (OMAN-MASTER-2026) on the login screen.',
                    '• عند التشغيل الأول، أدخل رابط قاعدة البيانات المركزية أو اختر التخزين المحلي.
'
                    '• في حال نسيان كلمة مرور المدير، استخدم كلمة المرور الأم الطارئة (OMAN-MASTER-2026).',
                  ),
                ),
                _buildHelpSectionTile(
                  _t('۲. راهنمای ثبت هزینه‌ها، جدول فشرده (با فونت ریز) و ذی‌حسابی مالیات VAT عمان', '2. Petty Cash, Compact Expense Table & Oman 5% VAT Comptroller', '٢. تسجيل المصاريف، الجدول المدمج، والرقابة الضريبية العمانية (5% VAT)'),
                  _t(
                    '• در منوی اول (تنخواه و هزینه)، سه زیربخش راست‌چین در اختیار شماست:
'
                    '  ۱- «ثبت سند هزینه / تنخواه»: فرم تمیز ثبت هزینه به همراه پنل ذی‌حسابی که به صورت هوشمند مشخص می‌کند آیا هزینه مشمول ۵٪ مالیات قابل استرداد عمان (Standard 5% Input VAT با فاکتور رسمی مالیاتی)، نرخ صفر (۰٪ مواد غذایی پایه) یا معاف است.
'
                    '  ۲- «جدول استاندارد و فشرده هزینه‌ها»: تمام هزینه‌های ثبت‌شده بدون شلوغ کردن فرم، در یک جدول مالی شیک با فونت ریز (11px) لیست می‌شوند.
'
                    '  ۳- «ذی‌حسابی و گزارش نهایی مالیات VAT عمان»: محاسبه خودکار مالیات فروش منهای مالیات خرید قابل استرداد و چاپ رسمی اظهارنامه با سربرگ CR: 1658937.',
                    '• Tab 1 is organized into 3 clean sub-tabs:
'
                    '  1- Clean Expense Entry Form with automatic Oman 5% VAT Comptroller classification.
'
                    '  2- Compact Expense DataGrid with 11px font for maximum space efficiency.
'
                    '  3- Final Oman Tax Authority (OTA) VAT Return & Comptroller Audit Report.',
                    '• ينقسم القسم الأول إلى ٣ تبويبات منظمة:
'
                    '  ١- نموذج تسجيل المصروفات مع التصنيف التلقائي لضريبة القيمة المضافة العمانية (5%).
'
                    '  ٢- جدول المصاريف المدمج بخط صغير وأنيق لتوفير المساحة.
'
                    '  ٣- التقرير النهائي للمراقب المالي وإقرار ضريبة القيمة المضافة العمانية.',
                  ),
                ),
                _buildHelpSectionTile(
                  _t('۳. راهنمای ۳ انبار، هشدار انقضا (FEFO)، فرمول تولید (BOM) و حواله خروج دو مرحله‌ای', '3. Three Warehouses, FEFO Expiry Alerts, BOM Costing & Two-Step Exit Slips', '٣. المستودعات الثلاثة، تنبيهات الصلاحية، تكلفة التصنيع وسندات الإخراج'),
                  _t(
                    '• انبار ۱ (مواد اولیه)، انبار ۲ (ملزومات بسته‌بندی) و انبار ۳ (محصول نهایی) دارای قفل موجودی منفی، رهگیری کد بچ و تاریخ انقضا (FEFO) هستند.
'
                    '• با ثبت هر سفارش فروش، «برگه خروج کالا از انبار» به صورت خودکار با سربرگ ۳ زبانه شرکت ارواد و شماره ثبت CR: 1658937 صادر و آماده چاپ می‌شود.',
                    '• Warehouses 1, 2, and 3 enforce negative-stock locks and FEFO batch expiry tracking.
'
                    '• Every sales order automatically issues an official printable Warehouse Exit Slip with Arwad CR: 1658937 header.',
                    '• تدعم المستودعات الثلاثة قفل المخزون السالب وتتبع تواريخ الصلاحية.
'
                    '• يصدر النظام تلقائياً سند إخراج بضاعة رسمي بشعار شركة أرواد ورقم السجل التجاري 1658937.',
                  ),
                ),
                _buildHelpSectionTile(
                  _t('۴. راهنمای سبد سفارش چندقلمی، پیش‌فاکتور، سقف اعتبار نسیه و دریافت چک مدت‌دار (PDC)', '4. Multi-Item Sales Cart, Proforma Quotes, Credit Limit & PDC Cheques', '٤. سلة الطلبات المتعددة، الفاتورة المبدئية، حد الائتمان والشيكات الآجلة'),
                  _t(
                    '• می‌توانید در یک فاکتور چندین قلم کالا اضافه کنید، تخفیف یا اشانتیون ثبت نمایید، یا پیش‌فاکتور رسمی صادر کنید.
'
                    '• تسویه حساب مشتریان هم به صورت نقدی، هم اقساطی (چندمرحله‌ای) و هم با چک مدت‌دار بانکی (PDC) قابل ثبت است.',
                    '• Create multi-line invoices, apply discounts/bonuses, issue proforma quotes, and record partial or PDC cheque payments.',
                    '• إمكانية إصدار فواتير متعددة الأصناف، وعروض أسعار، وتسجيل دفعات جزئية أو شيكات آجلة.',
                  ),
                ),
                _buildHelpSectionTile(
                  _t('۵. راهنمای تغییر زبان (FA / EN / AR)، انتخاب واحد پول (ریال / دلار) و بک‌آپ خودکار', '5. Tri-Lingual UI, Multi-Currency (OMR / USD) & Automated Backups', '٥. تغيير اللغة (فارسي / إنجليزي / عربي)، اختيار العملة والنسخ الاحتياطي'),
                  _t(
                    '• از نوار بالای برنامه می‌توانید در هر لحظه زبان برنامه را بین فارسی، انگلیسی و عربی و واحد پول را بین ریال عمان (OMR) و دلار آمریکا (USD) تغییر دهید.
'
                    '• در تب تنظیمات، سیستم بک‌آپ‌گیری زمان‌بندی‌شده خودکار و بازیابی یک‌کلیکی (Restore) حافظ اطلاعات شماست.',
                    '• Switch live between Persian, English, and Arabic, and between OMR and USD with historical rate locking and automated backups.',
                    '• يمكنك التبديل الفوري بين اللغات الثلاث والعملات (ريال عماني / دولار) مع النسخ الاحتياطي التلقائي.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSectionTile(String title, String body) {
    return Container(
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A5F))),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12, height: 1.55, color: Color(0xFF334155))),
        ],
      ),
    );
  }

}