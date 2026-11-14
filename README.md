# SafeFlow Flutter

Aplicación Flutter para supervisar la cadena de frío de productos y despachos. Conserva los módulos, permisos por rol, flujos operativos y el lenguaje visual de la app Android de SafeFlow.

## Arquitectura

La estructura sigue los bounded contexts y las capas DDD de Android. Cada módulo separa entidades y contratos en `domain`, casos de uso y reglas de negocio en `application`, adaptadores HTTP en `infrastructure/remote` y sus pantallas en `presentation`. El shell de workspace conserva navegación, permisos y carga transversal; no contiene las pantallas de cada contexto.

```text
lib/
├── core/
│   ├── domain/       # Errores de reglas de negocio
│   ├── models/       # Exportaciones compatibles de modelos por contexto
│   ├── serialization/
│   ├── network/
│   ├── theme/
│   └── widgets/
└── features/
    ├── iam/{domain,application,infrastructure/remote,presentation}/
    ├── inventory/{domain,application,infrastructure/remote,presentation}/
    ├── monitoring/{domain,application,infrastructure/remote,presentation}/
    ├── alerts/{domain,application,infrastructure/remote,presentation}/
    ├── logistics/{domain,application,infrastructure/remote,presentation}/
    ├── reporting/{domain,application,infrastructure/remote,presentation}/
    └── workspace/
        ├── application/
        └── presentation/ # Shell y navegación entre contextos
```

Los contextos corresponden a IAM, Inventory, Monitoring, Alerts, Logistics y Reporting del backend. Los contratos de repositorio se declaran en `domain` y los adaptadores REST los implementan en `infrastructure`. Cada contexto ejecuta sus operaciones desde servicios de aplicación; las reglas de inventario, alertas y logística se validan fuera del controlador de presentación. `WorkspaceController` coordina sesión, permisos y refresco transversal cada 30 segundos. `ApiClient` añade el token Bearer y conserva el token y su vencimiento localmente. El backend conserva la autoridad de autenticación, permisos y persistencia.

## Módulos

- **Resumen:** indicadores operativos.
- **Inventario:** productos, rangos térmicos, lotes e ingresos de unidades.
- **Riesgos:** productos con lecturas fuera de rango e historial térmico.
- **Alertas:** incidencias activas e historial, con registro de acciones correctivas.
- **Despachos:** creación, validación de sensor y temperatura, inicio de tránsito y confirmación de entrega.
- **Permisos:** administración de permisos por rol para cuentas ADMIN.
- **Cuenta:** rol, permisos activos y cierre de sesión.

La barra inferior muestra hasta tres módulos autorizados y la cuenta, siguiendo la navegación de Android. Los formularios y operaciones disponibles se ajustan al rol recibido al iniciar sesión.

## Diseño

Se usan los colores y tokens de SafeFlow, fuente Inter, tarjetas claras, estados térmicos diferenciados y componentes táctiles Material 3. El historial dibuja las mediciones y los límites térmicos del producto.

## API y ejecución

El host por defecto apunta al backend Azure:

```text
https://safeflow-api-chbaa6fxbbdja6b2.southeastasia-01.azurewebsites.net/api/v1/
```

Para cambiarlo al ejecutar o compilar, usa `--dart-define=SAFEFLOW_API_BASE_URL=https://host/api/v1/`.

```sh
flutter pub get
flutter run
```

La cuenta se autentica con `POST auth/sign-in`; las operaciones usan `Authorization: Bearer <jwt>`. Para endpoints, roles y reglas de autorización, consulta [safeflow-back](https://github.com/upc-pre-202620-1acc0238-4950-cryologic/safeflow-back).
