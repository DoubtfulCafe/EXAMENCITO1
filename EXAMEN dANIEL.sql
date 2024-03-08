--Todos los procedimientos/funciones deberán estar creados dentro de un paquete con el nombre
--PKG_<SU_PRIMER_NOMBRE>_<SU_PRIMER_APELLIDO>, para las pruebas de cada uno utilizar bloques
--anónimos debidamente comentados.
--Inserte en las tablas la información que considere necesaria, puede adjuntar los inserts como parte --de su
--solución. Además cree las secuencias que necesite para los campos que son llaves primarias.
--Dar solución a los siguientes incisos:
--1. Desarrollar un procedimiento almacenado llamado P_ACTUALIZAR_SUSCRIPTORES. Este procedimiento
--almacenado actualizará la cantidad de suscriptores de un canal de YouTube específico. Tomará como --entrada el
--código del canal y el código del usuario que se agregará. El procedimiento verificará si el canal y --el usuario existe
--y luego insertará el suscriptor en la tabla de usuarios por canal y luego actualizará la cantidad de --suscriptores
--sumando uno . Además, si la cantidad de suscriptores supera a 10, enviará una notificación al --usuario dueño del
--canal felicitandolo por su logro. Para el envío de notificaciones crear un procedimiento llamado
--P_GUARDAR_NOTIFICACION que reciba como parametros los campos de la tabla y los use para insertar un --nuevo
--registro en la tabla tbl_notificaciones.
--Para verificar si los registros indicados existen utilizar excepciones personalizadas y enviar un --mensaje de salida
--indicando cual es el error.--

CREATE OR REPLACE PROCEDURE P_ACTUALIZAR_SUSCRIPTORES(
    P_USUARIO_ID TBL_USUARIOS.CODIGO_USUARIO%TYPE,
    P_CANAL_ID TBL_CANALES.CODIGO_CANAL%TYPE
)AS
    V_EXISTE_USUARIO EXCEPTION;
    V_EXISTE_CANAL EXCEPTION;
    V_CANTIDAD_USUARIOS NUMBER;
    V_CANTIDAD_CANALES NUMBER;
BEGIN
    SELECT COUNT(1) 
    INTO V_CANTIDAD_USUARIOS
    FROM tbl_usuarios
    WHERE CODIGO_USUARIO  = P_USUARIO_ID;
    
    SELECT COUNT(1) 
    INTO V_CANTIDAD_CANALES
    FROM tbl_canales
    WHERE CODIGO_CANAL  = P_CANAL_ID; 
    
    IF (v_cantidad_canales <=0 ) THEN
        RAISE V_EXISTE_CANAL ;
    ELSE IF ( V_CANTIDAD_USUARIOS <=0)THEN
        RAISE  V_EXISTE_USUARIO;
    ELSE 
      DBMS_OUPUTLINE('VAMOS BIEN');
    END IF;
    
    UPDATE TBL_USUARIOS_X_CANAL
    SET codigo_usuario =  P_USUARIO_ID,
    codigo_canal= P_CANAL_ID,
    FECHA_SUBCRIPCION= SYSDATE;
    
    UPDATE TBL_CANALES
    SET cantidad_suscriptores = cantidad_suscriptores +1;
    
     COMMIT;
    DBMS_OUTPUT.PUT_LINE('se subscribio');
    
EXCEPTION
    WHEN V_EXISTE_USUARIO THEN
        DBMS_OUTPUT.PUT_LINE('NO EXISTE EL USUARIO');
        ROLLBACK;
        
     WHEN V_EXISTE_CANAL THEN
        DBMS_OUTPUT.PUT_LINE('NO EXISTE EL CANAL');
        ROLLBACK;
        
END;


---Desarrollar un procedimiento almacenado para guardar denuncias de videos P_DENUNCIAR_VIDEO, el
---procedimiento debe recibir el video que se denunciará y toda la información relacionada. Se debe verificar si el
---video existe y gestionarlo con excepciones personalizadas, enviar un parametro de salida con el estatus de la
---ejecución del procedimiento.
---Verificar si la cantidad de denuncias del video exceden las 5 denuncias, en caso de ser así se deberá cambiar el
---sido denunciado y bloqueado.
---estado del video a bloqueado, además se deberá enviar una notificación al dueño del video de que su video ha
    