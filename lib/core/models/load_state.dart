enum LoadState {
  loading,
  success,
  empty,
  error,
}

extension LoadStateX on LoadState {
  bool get isLoading => this == LoadState.loading;
  bool get isSuccess => this == LoadState.success;
  bool get isEmpty => this == LoadState.empty;
  bool get isError => this == LoadState.error;
}
