import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/core/network/api_client.dart';
import 'package:client/src/core/storage/app_storage.dart';
import 'package:client/src/features/admin/data/admin_repository.dart';
import 'package:client/src/features/auth/data/auth_repository.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/features/educational_data/data/educational_data_repository.dart';
import 'package:client/src/features/saved_infographics/data/saved_infographics_repository.dart';

import 'app_router.dart';
import 'app_theme.dart';

class InfographicApp extends StatefulWidget {
  const InfographicApp({super.key});

  @override
  State<InfographicApp> createState() => _InfographicAppState();
}

class _InfographicAppState extends State<InfographicApp> {
  late final AppStorage _storage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final EducationalDataRepository _educationalDataRepository;
  late final SavedInfographicsRepository _savedInfographicsRepository;
  late final AdminRepository _adminRepository;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _storage = AppStorage();

    _apiClient = ApiClient(
      storage: _storage,
    );

    _authRepository = AuthRepository(
      apiClient: _apiClient,
      storage: _storage,
    );

    _educationalDataRepository = EducationalDataRepository(
      apiClient: _apiClient,
    );

    _savedInfographicsRepository = SavedInfographicsRepository(
      apiClient: _apiClient,
    );

    _adminRepository = AdminRepository(
      apiClient: _apiClient,
    );

    _authBloc = AuthBloc(
      authRepository: _authRepository,
    )..add(const AuthStarted());

    _router = createAppRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(
          value: _authRepository,
        ),
        RepositoryProvider.value(
          value: _educationalDataRepository,
        ),
        RepositoryProvider.value(
          value: _savedInfographicsRepository,
        ),
        RepositoryProvider.value(
          value: _adminRepository,
        ),
      ],
      child: BlocProvider.value(
        value: _authBloc,
        child: MaterialApp.router(
          title: 'Генерация инфографики',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}