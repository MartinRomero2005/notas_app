// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notas_app/main.dart';
import 'package:notas_app/models/nota.dart';
import 'package:notas_app/services/api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra acceso exclusivo para docentes', (tester) async {
    await tester.pumpWidget(const NotasApp());

    expect(find.text('Gestión Académica'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Estudiante'), findsNothing);
  });

  test('permite crear, actualizar, eliminar y sincronizar notas', () async {
    final api = ApiService.instance;
    final creada = await api.crearNota(
      Nota(
        estudianteId: 99,
        docenteId: 1,
        estudiante: 'Prueba docente',
        asignatura: 'Evaluación',
        calificacion: 4,
        comentario: '',
        fecha: DateTime(2026, 9, 12),
      ),
    );

    expect(creada.id, isNotNull);
    expect(creada.sincronizada, isFalse);

    final actualizada = await api.actualizarNota(
      creada.copyWith(calificacion: 4.5),
    );
    expect(actualizada.calificacion, 4.5);

    expect(await api.sincronizarConLaNube(), 1);
    expect(
      (await api.obtenerNotas())
          .singleWhere((nota) => nota.id == creada.id)
          .sincronizada,
      isTrue,
    );

    await api.eliminarNota(creada.id!);
    expect(
      (await api.obtenerNotas()).any((nota) => nota.id == creada.id),
      isFalse,
    );
  });
}
