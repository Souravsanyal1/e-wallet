class ChannelModel {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? avatarPath;
  final bool isPublic;
  final String? requiredPlanSlug;
  final int subscriberCount;
  final bool isSubscribed;

  const ChannelModel({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.avatarPath,
    this.isPublic = true,
    this.requiredPlanSlug,
    this.subscriberCount = 0,
    this.isSubscribed = false,
  });

  bool get isTokenGated => !isPublic || requiredPlanSlug != null;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      avatarPath: json['avatar_path'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      requiredPlanSlug: json['required_plan_slug'] as String?,
      subscriberCount: json['subscriber_count'] as int? ?? 0,
      isSubscribed: json['is_subscribed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'avatar_path': avatarPath,
        'is_public': isPublic,
        'required_plan_slug': requiredPlanSlug,
        'subscriber_count': subscriberCount,
        'is_subscribed': isSubscribed,
      };

  ChannelModel copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    String? avatarPath,
    bool? isPublic,
    String? requiredPlanSlug,
    int? subscriberCount,
    bool? isSubscribed,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      avatarPath: avatarPath ?? this.avatarPath,
      isPublic: isPublic ?? this.isPublic,
      requiredPlanSlug: requiredPlanSlug ?? this.requiredPlanSlug,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

class PlanModel {
  final String id;
  final String slug;
  final String title;
  final String description;
  final double displayPrice;
  final String tokenSymbol;
  final String tokenAddress;
  final String receiverAddress;
  final int chainId;
  final int? usdListPriceCents;
  final int durationDays;
  final List<String> perks;

  const PlanModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.displayPrice,
    this.tokenSymbol = 'Token',
    this.tokenAddress = '',
    this.receiverAddress = '',
    this.chainId = 97,
    this.usdListPriceCents,
    this.durationDays = 30,
    required this.perks,
  });
}

class PremiumQuote {
  final String quoteId;
  final String planId;
  final String amount;
  final String tokenAddress;
  final String receiverAddress;
  final String tokenSymbol;
  final int tokenDecimals;
  final int chainId;
  final int durationDays;
  final int? usdListPriceCents;
  final DateTime expiresAt;

  const PremiumQuote({
    required this.quoteId,
    required this.planId,
    required this.amount,
    required this.tokenAddress,
    required this.receiverAddress,
    required this.tokenSymbol,
    required this.tokenDecimals,
    required this.chainId,
    required this.durationDays,
    required this.expiresAt,
    this.usdListPriceCents,
  });

  factory PremiumQuote.fromJson(Map<String, dynamic> json) => PremiumQuote(
        quoteId: json['quoteId'] as String,
        planId: json['planId'] as String,
        amount: json['amount'] as String,
        tokenAddress: json['token'] as String,
        receiverAddress: json['receiver'] as String,
        tokenSymbol: json['tokenSymbol'] as String,
        tokenDecimals: json['tokenDecimals'] as int,
        chainId: json['chainId'] as int,
        durationDays: json['durationDays'] as int,
        usdListPriceCents: json['usdListPriceCents'] as int?,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

class PremiumPaymentResult {
  final String status;
  final String? expiresAt;

  const PremiumPaymentResult({required this.status, this.expiresAt});

  bool get isConfirmed => status == 'confirmed';
}
