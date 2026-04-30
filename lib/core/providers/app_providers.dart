import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// アプリケーションの基本的なプロバイダー定義
/// 今後のタスクで具体的な機能プロバイダーが追加される

/// APIクライアントプロバイダー
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// アプリケーションの状態を管理するプロバイダー
final appStateProvider = StateProvider<AppState>((ref) {
  return const AppState.initial();
});

/// アプリケーションの状態を表すクラス
class AppState {
  final bool isLoading;
  final String? errorMessage;
  
  const AppState({
    this.isLoading = false,
    this.errorMessage,
  });
  
  const AppState.initial() : this();
  
  const AppState.loading() : this(isLoading: true);
  
  const AppState.error(String message) : this(errorMessage: message);
  
  AppState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}