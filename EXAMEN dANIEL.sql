---1. Desarrollar un procedimiento almacenado llamado P_ACTUALIZAR_SUSCRIPTORES. Este procedimiento
---almacenado actualizará la cantidad de suscriptores de un canal de YouTube específico. Tomará como entrada el
---código del canal y el código del usuario que se agregará. El procedimiento verificará si el canal y el usuario existe
---y luego insertará el suscriptor en la tabla de usuarios por canal y luego actualizará la cantidad de suscriptores
---sumando uno . Además, si la cantidad de suscriptores supera a 10, enviará una notificación al usuario dueño del
---canal felicitandolo por su logro. Para el envío de notificaciones crear un procedimiento llamado
---P_GUARDAR_NOTIFICACION que reciba como parametros los campos de la tabla y los use para insertar un nuevo
---registro en la tabla tbl_notificaciones.
---Para verificar si los registros indicados existen utilizar excepciones personalizadas y enviar un mensaje de salida
---indicando cual es el error.

CREATE OR REPLACE PROCEDURE P_ACTUALIZAR_SUSCRIPTORES (
    P_USUARIO_ID tbl_usuarios.codigo_usuario%TYPE,
    P_CANAL_ID tbl_canales.codigo_canal%TYPE
) AS
    V_EXISTE_USUARIO EXCEPTION;
    V_EXISTE_CANAL EXCEPTION;
    V_CANTIDAD_USUARIOS NUMBER;
    V_CANTIDAD_CANALES NUMBER;
BEGIN
    -- Verificar si el usuario existe
    SELECT COUNT(1) INTO V_CANTIDAD_USUARIOS
    FROM tbl_usuarios
    WHERE codigo_usuario = P_USUARIO_ID;

    IF V_CANTIDAD_USUARIOS <= 0 THEN
        RAISE V_EXISTE_USUARIO;
    END IF;

    -- Verificar si el canal existe
    SELECT COUNT(1) INTO V_CANTIDAD_CANALES
    FROM tbl_canales
    WHERE codigo_canal = P_CANAL_ID;

    IF V_CANTIDAD_CANALES <= 0 THEN
        RAISE V_EXISTE_CANAL;
    END IF;

    -- Actualizar la tabla tbl_usuarios_x_canal
    UPDATE tbl_usuarios_x_canal
    SET codigo_usuario = P_USUARIO_ID,
        codigo_canal = P_CANAL_ID,
        fecha_suscripcion = SYSDATE
    WHERE codigo_usuario = P_USUARIO_ID
    AND codigo_canal = P_CANAL_ID;

    -- Actualizar la cantidad de suscriptores en el canal
    UPDATE tbl_canales
    SET cantidad_suscriptores = cantidad_suscriptores + 1
    WHERE codigo_canal = P_CANAL_ID;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Se ha suscrito exitosamente.');

EXCEPTION
    WHEN V_EXISTE_USUARIO THEN
        DBMS_OUTPUT.PUT_LINE('Error: El usuario especificado no existe.');
        ROLLBACK;

    WHEN V_EXISTE_CANAL THEN
        DBMS_OUTPUT.PUT_LINE('Error: El canal especificado no existe.');
        ROLLBACK;
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
END;

---2. Usar el procedimieto P_GUARDAR_NOTIFICACION para el envío de notificaciones desde los siguientes
---procedimientos:
---a. Crear un procedimiento llamado P_GUARDAR_VIDEO para guardar un video usando los parametros de
---entrada del procedimiento y luego de ello verificar cual es el canal correspondiente para luego obtener
---la lista de los usuarios suscritos a dicho canal. Por ultimo, enviar una notificacion a cada usuario suscrito
---indicando que se ha subido un nuevo video al canal al cual está suscrito. Gestionar exceptiones
---personalizadas para verificar la existencia del usuario y el canal.
---b. Crear un procedimiento llamado P_GUARDAR_COMENTARIO para guardar un comentario usando los
---parametros de entrada del procedimiento y luego de ello enviar una notificación al usuario dueño del
---video que se cometó, indicando en la notificación el contenido del comentario. Gestionar exceptiones
---personalizadas para verificar la existencia del usuario y el video.


CREATE SEQUENCE S_ID_NOTIFICACIONES START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE PROCEDURE P_GUARDAR_NOTIFICACION(
    P_CODIGO_NOTIFICACION TBL_NOTIFICACIONES.CODIGO_NOTIFICACION%TYPE,
    P_CODIGO_USUARIO_DESTINO TBL_NOTIFICACIONES.CODIGO_USUARIO_DESTINO%TYPE,
    P_FECHA_HORA_ENVIO TBL_NOTIFICACIONES.FECHA_HORA_ENVIO%TYPE,
    P_TEXTO_NOTIFICACION TBL_NOTIFICACIONES.TEXTO_NOTIFICACION%TYPE,
    P_CODIGO_VIDEO TBL_NOTIFICACIONES.CODIGO_VIDEO%TYPE,
    P_CODIGO_USUARIO_ORIGEN TBL_NOTIFICACIONES.CODIGO_USUARIO_ORIGEN%TYPE,
    P_CODIGO_RESULTADO OUT NUMBER,
    P_CODIGO_MENSAJE OUT VARCHAR2
) AS
BEGIN
    ---INSERTAMOS
    INSERT INTO TBL_NOTIFICACIONES
    (
        CODIGO_NOTIFICACION,
        CODIGO_USUARIO_DESTINO,
        FECHA_HORA_ENVIO,
        TEXTO_NOTIFICACION,
        CODIGO_VIDEO,
        CODIGO_USUARIO_ORIGEN
    )
    VALUES
    (
        P_CODIGO_NOTIFICACION,
        P_CODIGO_USUARIO_DESTINO,
        P_FECHA_HORA_ENVIO,
        P_TEXTO_NOTIFICACION,
        P_CODIGO_VIDEO,
        P_CODIGO_USUARIO_ORIGEN
    );
    
    P_CODIGO_RESULTADO := 200;
    P_CODIGO_MENSAJE := 'INSERTADO';
EXCEPTION
    WHEN OTHERS THEN
        P_CODIGO_RESULTADO := SQLCODE;
        P_CODIGO_MENSAJE := SQLERRM;
        ROLLBACK;
END P_GUARDAR_NOTIFICACION;


CREATE OR REPLACE PROCEDURE P_GUARDAR_VIDEO(
    P_CODIGO_VIDEO TBL_VIDEOS.CODIGO_VIDEO%TYPE,
    P_CODIGO_USUARIO TBL_VIDEOS.CODIGO_USUARIO%TYPE,
    P_CODIGO_ESTADO_VIDEO TBL_VIDEOS.CODIGO_ESTADO_VIDEO%TYPE,
    P_CODIGO_IDIOMA TBL_VIDEOS.CODIGO_IDIOMA%TYPE,
    P_CODIGO_CANAL TBL_VIDEOS.CODIGO_CANAL%TYPE,
    P_NOMBRE_VIDEO TBL_VIDEOS.NOMBRE_VIDEO%TYPE,
    P_RESOLUCION TBL_VIDEOS.RESOLUCION%TYPE,
    P_DURACION_SEGUNDOS TBL_VIDEOS.DURACION_SEGUNDOS%TYPE,
    P_CANTIDAD_LIKES TBL_VIDEOS.CANTIDAD_LIKES%TYPE,
    P_CANTIDAD_DISLIKES TBL_VIDEOS.CANTIDAD_DISLIKES%TYPE,
    P_CANTIDAD_VISUALIZACIONES TBL_VIDEOS.CANTIDAD_VISUALIZACIONES%TYPE,
    P_FECHA_SUBIDA TBL_VIDEOS.FECHA_SUBIDA%TYPE,
    P_DESCRIPCION TBL_VIDEOS.DESCRIPCION%TYPE,
    P_CANTIDAD_SHARES TBL_VIDEOS.CANTIDAD_SHARES%TYPE,
    P_URL TBL_VIDEOS.URL%TYPE,
    P_CODIGO_RESULTADO OUT NUMBER,
    P_CODIGO_MENSAJE OUT VARCHAR2
) AS
    V_CANAL NUMBER;
    V_USUARIO NUMBER;
BEGIN
    
    -- Verificar si el canal existe
    SELECT COUNT(1)
    INTO V_CANAL
    FROM TBL_CANALES 
    WHERE CODIGO_CANAL = P_CODIGO_CANAL;

    IF (V_CANAL <= 0) THEN
        -- Canal no existe
        P_CODIGO_RESULTADO := 1;
        P_CODIGO_MENSAJE := 'CANAL NO EXISTE';
        RETURN;
    END IF;
        
    -- Verificar si el usuario existe
    SELECT COUNT(1)
    INTO V_USUARIO
    FROM TBL_USUARIOS 
    WHERE CODIGO_USUARIO = P_CODIGO_USUARIO;

    IF (V_USUARIO <= 0) THEN
        -- Usuario no existe
        P_CODIGO_RESULTADO := 1;
        P_CODIGO_MENSAJE := 'USUARIO NO EXISTE';
        RETURN;
    END IF;
    
    -- Insertar video
    INSERT INTO TBL_VIDEOS
    (
        CODIGO_VIDEO,
        CODIGO_USUARIO,
        CODIGO_ESTADO_VIDEO,
        CODIGO_IDIOMA,
        CODIGO_CANAL,
        NOMBRE_VIDEO,
        RESOLUCION,
        DURACION_SEGUNDOS,
        CANTIDAD_LIKES,
        CANTIDAD_DISLIKES,
        CANTIDAD_VISUALIZACIONES,
        FECHA_SUBIDA,
        DESCRIPCION,
        CANTIDAD_SHARES,
        URL
    )
    VALUES
    (
        P_CODIGO_VIDEO,
        P_CODIGO_USUARIO,
        P_CODIGO_ESTADO_VIDEO,
        P_CODIGO_IDIOMA,
        P_CODIGO_CANAL,
        P_NOMBRE_VIDEO,
        P_RESOLUCION,
        P_DURACION_SEGUNDOS,
        P_CANTIDAD_LIKES,
        P_CANTIDAD_DISLIKES,
        P_CANTIDAD_VISUALIZACIONES,
        P_FECHA_SUBIDA,
        P_DESCRIPCION,
        P_CANTIDAD_SHARES,
        P_URL
    );
    
    -- Enviar notificaciones a usuarios suscritos al canal
    FOR REGISTRO IN ( SELECT CODIGO_USUARIO FROM TBL_USUARIOS_X_CANAL WHERE CODIGO_CANAL = P_CODIGO_CANAL) LOOP
        -- Insertar notificación directamente
        INSERT INTO TBL_NOTIFICACIONES
        (
            CODIGO_NOTIFICACION,
            CODIGO_USUARIO_DESTINO,
            FECHA_HORA_ENVIO,
            TEXTO_NOTIFICACION,
            CODIGO_VIDEO,
            CODIGO_USUARIO_ORIGEN
        )
        VALUES
        (
            S_ID_NOTIFICACIONES.NEXTVAL,
            REGISTRO.CODIGO_USUARIO,
            SYSDATE,
            'Tenemos un nuevo video chavales: ' || P_NOMBRE_VIDEO,
            P_CODIGO_VIDEO,
            P_CODIGO_USUARIO
        );
    END LOOP;
    
    P_CODIGO_RESULTADO := 200;
    P_CODIGO_MENSAJE := 'Vamos muy bien';
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SQLCODE' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('SQLERRM' || SQLERRM);
        ROLLBACK;
END P_GUARDAR_VIDEO;
CREATE OR REPLACE PROCEDURE P_GUARDAR_COMENTARIO(
    P_CODIGO_COMENTARIO TBL_COMENTARIOS.CODIGO_COMENTARIO%TYPE,
    P_CODIGO_COMENTARIO_PADRE TBL_COMENTARIOS.CODIGO_COMENTARIO_PADRE%TYPE,
    P_CODIGO_USUARIO TBL_COMENTARIOS.CODIGO_USUARIO%TYPE,
    P_CODIGO_VIDEO TBL_COMENTARIOS.CODIGO_VIDEO%TYPE,
    P_COMENTARIO TBL_COMENTARIOS.COMENTARIO%TYPE,
    P_FECHA_PUBLICACION TBL_COMENTARIOS.FECHA_PUBLICACION%TYPE,
    P_CANTIDAD_LIKES TBL_COMENTARIOS.CANTIDAD_LIKES%TYPE,
    P_CODIGO_RESULTADO OUT NUMBER,
    P_CODIGO_MENSAJE OUT VARCHAR2
) AS
    V_CODIGO_USUARIO_PROPIETARIO TBL_CANALES.CODIGO_USUARIO%TYPE;
    V_USUARIO NUMBER;
    V_VIDEO NUMBER;
BEGIN
    -- Verificamos el usuario
    SELECT COUNT(1) 
    INTO V_USUARIO 
    FROM TBL_USUARIOS 
    WHERE CODIGO_USUARIO = P_CODIGO_USUARIO;
    IF V_USUARIO = 0 THEN
        P_CODIGO_RESULTADO := 1;
        P_CODIGO_MENSAJE := ' no existe el usuario';
        RETURN;
    END IF;

    -- Verificamos  el video 
    SELECT COUNT(1) 
    INTO V_VIDEO 
    FROM TBL_VIDEOS 
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;
    IF V_VIDEO = 0 THEN
        P_CODIGO_RESULTADO := 200;
        P_CODIGO_MENSAJE := ' no existe el videooo';
        RETURN;
    END IF;

    -- retornamos el usuario del video
    SELECT CODIGO_USUARIO INTO V_CODIGO_USUARIO_PROPIETARIO
    FROM TBL_VIDEOS
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

    -- Insertaamos un comentario
    INSERT INTO TBL_COMENTARIOS
    (
        CODIGO_COMENTARIO,
        CODIGO_COMENTARIO_PADRE,
        CODIGO_USUARIO,
        CODIGO_VIDEO,
        COMENTARIO,
        FECHA_PUBLICACION,
        CANTIDAD_LIKES
    )
    VALUES
    (
        P_CODIGO_COMENTARIO,
        P_CODIGO_COMENTARIO_PADRE,
        P_CODIGO_USUARIO,
        P_CODIGO_VIDEO,
        P_COMENTARIO,
        P_FECHA_PUBLICACION,
        P_CANTIDAD_LIKES
    );

    -- Enviamos la notificaciones
    P_GUARDAR_NOTIFICACION(
        P_CODIGO_NOTIFICACION => S_ID_NOTIFICACIONES.NEXTVAL,
        P_CODIGO_USUARIO_DESTINO => V_CODIGO_USUARIO_PROPIETARIO,
        P_FECHA_HORA_ENVIO => SYSDATE,
        P_TEXTO_NOTIFICACION => 'comentario generico',
        P_CODIGO_VIDEO => P_CODIGO_VIDEO,
        P_CODIGO_USUARIO_ORIGEN => P_CODIGO_USUARIO,
        P_CODIGO_RESULTADO => P_CODIGO_RESULTADO,
        P_CODIGO_MENSAJE => P_CODIGO_MENSAJE
    );


    P_CODIGO_RESULTADO := 200;
    P_CODIGO_MENSAJE := 'se guardo el comentario';
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SQLCODE' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('SQLERRM' || SQLERRM);
        ROLLBACK;
END P_GUARDAR_COMENTARIO;

---4. Desarrollar un procedimiento almacenado para guardar denuncias de videos P_DENUNCIAR_VIDEO, el
---procedimiento debe recibir el video que se denunciará y toda la información relacionada. Se debe verificar si el
---video existe y gestionarlo con excepciones personalizadas, enviar un parametro de salida con el estatus de la
---ejecución del procedimiento.
---Verificar si la cantidad de denuncias del video exceden las 5 denuncias, en caso de ser así se deberá cambiar el
---estado del video a bloqueado, además se deberá enviar una notificación al dueño del video de que su video ha
---sido denunciado y bloqueado.

CREATE OR REPLACE PROCEDURE P_DENUNCIAR_VIDEO(
    P_CODIGO_DENUNCIA TBL_DENUNCIAS.CODIGO_DENUNCIA%TYPE,
    P_CODIGO_TIPO_DENUNCIA TBL_DENUNCIAS.CODIGO_TIPO_DENUNCIA%TYPE,
    P_CODIGO_ESTADO_DENUNCIA TBL_DENUNCIAS.CODIGO_ESTADO_DENUNCIA%TYPE,
    P_CODIGO_USUARIO TBL_DENUNCIAS.CODIGO_USUARIO%TYPE,
    P_CODIGO_VIDEO TBL_DENUNCIAS.CODIGO_VIDEO%TYPE,
    P_DESCRIPCION TBL_DENUNCIAS.DESCRIPCION%TYPE,
    P_FECHA_DENUNCIA TBL_DENUNCIAS.FECHA_DENUNCIA%TYPE,
    P_CODIGO_RESULTADO OUT NUMBER,
    P_CODIGO_MENSAJE OUT VARCHAR2
) AS
    V_CODIGO_USUARIO_PROPIETARIO TBL_CANALES.CODIGO_USUARIO%TYPE;
    V_CANT_DENUNCIAS NUMBER;
BEGIN
    -- Verificar si el video existe y obtener el usuario propietario
    BEGIN
        SELECT CODIGO_USUARIO
        INTO V_CODIGO_USUARIO_PROPIETARIO
        FROM TBL_VIDEOS
        WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no se encuentra el video, establecer los códigos de resultado y mensaje
            P_CODIGO_RESULTADO := 2;
            P_CODIGO_MENSAJE := 'El video no existe';
            RETURN;
    END;

    -- Verificar si el usuario existe
    SELECT COUNT(1) INTO V_CANT_DENUNCIAS
    FROM TBL_DENUNCIAS
    WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

    IF V_CANT_DENUNCIAS > 5 THEN
        -- Si hay más de 5 denuncias, actualizar el estado del video
        UPDATE TBL_VIDEOS
        SET CODIGO_ESTADO_VIDEO = P_CODIGO_ESTADO_DENUNCIA
        WHERE CODIGO_VIDEO = P_CODIGO_VIDEO;

        -- Enviar notificación al propietario del video
        -- (Código de notificación al propietario aquí)

        -- Establecer códigos de resultado y mensaje
        P_CODIGO_RESULTADO := 200;
        P_CODIGO_MENSAJE := 'El video ha sido bloqueado debido a múltiples denuncias';
    ELSE
        -- Si no hay más de 5 denuncias, insertar la denuncia
        INSERT INTO TBL_DENUNCIAS (
            CODIGO_DENUNCIA,
            CODIGO_TIPO_DENUNCIA,
            CODIGO_ESTADO_DENUNCIA,
            CODIGO_USUARIO,
            CODIGO_VIDEO,
            DESCRIPCION,
            FECHA_DENUNCIA
        ) VALUES (
            P_CODIGO_DENUNCIA,
            P_CODIGO_TIPO_DENUNCIA,
            P_CODIGO_ESTADO_DENUNCIA,
            P_CODIGO_USUARIO,
            P_CODIGO_VIDEO,
            P_DESCRIPCION,
            P_FECHA_DENUNCIA
        );

        -- Establecer códigos de resultado y mensaje
        P_CODIGO_RESULTADO := 200;
        P_CODIGO_MENSAJE := 'Denuncia registrada ';
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Si hay alguna excepción, se mostrara la información del error y hara un rollback
        DBMS_OUTPUT.PUT_LINE('SQLCODE' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('SQLERRM' || SQLERRM);
        ROLLBACK;
END P_DENUNCIAR_VIDEO;
