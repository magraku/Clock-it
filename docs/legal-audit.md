# Clock it: revisión legal

| Riesgo | Resultado |
| --- | --- |
| Edad al registrarse | El alta exige confirmar que se tienen al menos 16 años. Es una declaración, no una verificación de identidad, y no recoge fecha de nacimiento. No se aplica a las cuentas existentes al iniciar sesión. |
| Fuentes de terceros | Epilogue, Anton y Outfit ya se distribuían con la app. El build web sirve CanvasKit, la fuente Roboto incluida con el SDK y los 724 subconjuntos Noto (OFL 1.1) desde el propio sitio. El paquete Noto se descarga y verifica al compilar, no en el navegador del usuario. Se siguen usando Firebase Auth y Firestore, incluido el SDK web de Google; eso es independiente de las fuentes. |
| Grabación de sesiones | No se encontró SDK ni integración de grabación de sesiones o analítica de marketing en la app. |
| Correos de marketing | No existen en la app. Los correos de restablecimiento de contraseña de Firebase son transaccionales y los solicita la persona usuaria. |
| Renovaciones | No existe suscripción, pago, muro de pago ni botón de compra. |
| Contenido de usuarios / DMCA | Firestore aloja registros, metas, preferencias y texto introducido por cada cuenta. Son privados: no hay publicaciones públicas, contenido compartido ni archivos de usuario servidos a terceros. Importar un respaldo no aloja el archivo; solo restaura los datos de la cuenta. |

## Unión Europea

- El alta enlaza al aviso de privacidad y las condiciones y requiere aceptarlas/reconocerlas; también están en Perfil. Aceptar las condiciones no se usa como consentimiento de marketing ni como base para tratar los datos necesarios para prestar el servicio.
- El aviso identifica a la persona responsable del tratamiento e indica el correo para consultas de privacidad y ejercicio de derechos en ambos idiomas.
- **Antes de publicar el aviso:** añadir los datos de contacto del representante de la UE o del DPD si corresponde. Verificar y concretar los plazos de conservación (también en registros y copias de proveedores), las regiones reales y las transferencias internacionales y sus garantías. Revisar los acuerdos con Google/Firebase y Vercel y verificar que no se haya activado analítica o grabación fuera del código. El borrador no certifica el cumplimiento.
- Perfil → Borrar cuenta ya vuelve a autenticar, elimina `users/{uid}` y luego elimina la cuenta de Firebase Auth. Las reglas versionadas permiten borrar únicamente al titular de cada documento; no necesitan cambios. Corroborar que el proyecto [tenga publicadas esas reglas](https://console.firebase.google.com/project/clock-it-83703/firestore/rules) y que la configuración de copias y retención respete el aviso.
- Perfil → Respaldo exporta metas, horas y preferencias en JSON; la exportación web ya no depende de la API de archivos temporales nativa. Este respaldo no incluye el correo ni otros metadatos de Firebase Auth: las solicitudes de acceso deben cubrir también esos datos cuando proceda.
- No se necesita un banner para el almacenamiento estrictamente necesario por sí solo. El código usa almacenamiento de sesión y caché para autenticación y sincronización; no se encontró almacenamiento opcional de publicidad ni seguimiento. Revisar la configuración de producción de los proveedores por separado.

## Compilar para la web

Usar `bash scripts/vercel-build.sh install` y `bash scripts/vercel-build.sh build` (el mismo proceso que Vercel). `flutter run -d chrome` y un `flutter build web` directo conservan las fuentes de respaldo predeterminadas del SDK; solo el script de despliegue copia y activa las fuentes Noto locales. Al actualizar Flutter, verificar el paquete `flutter/flutter_font_fallbacks` en el archivo `DEPS` del SDK y actualizar la versión y la suma de comprobación del script si cambian.
