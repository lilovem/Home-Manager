/// הגדרות קישורי תשלום ל-household - נשמר פעם אחת, נערך לפי הצורך.
/// חשמל תמיד נפרד; מים+ארנונה יכולים להיות ביחד או בנפרד.
class BillLinkSettings {
  final String? bitUrl;
  final String? payboxUrl;
  final String? electricityUrl;
  final bool? waterAndTaxCombined; // null = טרם הוגדר
  final String? combinedWaterTaxUrl;
  final String? waterUrl;
  final String? taxUrl;

  const BillLinkSettings({
    this.bitUrl,
    this.payboxUrl,
    this.electricityUrl,
    this.waterAndTaxCombined,
    this.combinedWaterTaxUrl,
    this.waterUrl,
    this.taxUrl,
  });

  bool get isElectricityConfigured => electricityUrl != null && electricityUrl!.isNotEmpty;

  bool get isWaterTaxConfigured {
    if (waterAndTaxCombined == null) return false;
    if (waterAndTaxCombined == true) {
      return combinedWaterTaxUrl != null && combinedWaterTaxUrl!.isNotEmpty;
    }
    return waterUrl != null && waterUrl!.isNotEmpty && taxUrl != null && taxUrl!.isNotEmpty;
  }

  factory BillLinkSettings.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const BillLinkSettings();
    return BillLinkSettings(
      bitUrl: data['bitUrl'] as String?,
      payboxUrl: data['payboxUrl'] as String?,
      electricityUrl: data['electricityUrl'] as String?,
      waterAndTaxCombined: data['waterAndTaxCombined'] as bool?,
      combinedWaterTaxUrl: data['combinedWaterTaxUrl'] as String?,
      waterUrl: data['waterUrl'] as String?,
      taxUrl: data['taxUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bitUrl': bitUrl,
      'payboxUrl': payboxUrl,
      'electricityUrl': electricityUrl,
      'waterAndTaxCombined': waterAndTaxCombined,
      'combinedWaterTaxUrl': combinedWaterTaxUrl,
      'waterUrl': waterUrl,
      'taxUrl': taxUrl,
    };
  }
}

