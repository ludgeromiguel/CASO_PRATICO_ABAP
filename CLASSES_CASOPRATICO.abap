*&---------------------------------------------------------------------*
*&  Include           ZFORM16_GINASIO_CLASSES
*&---------------------------------------------------------------------*

CLASS lcl_ginasio DEFINITION.

  PUBLIC SECTION.

    METHODS: init.

    TYPES: table_cliente TYPE TABLE OF zform16_client_t.

    CLASS-METHODS:  criar_cliente," IMPORTING iv_status TYPE I,
      modificar_cliente IMPORTING iv_id_cliente TYPE zform16_client_t-id_cliente,
      remover_cliente IMPORTING iv_id_cliente TYPE zform16_client_t-id_cliente,
      exportar_clientes IMPORTING iv_file TYPE rlgrap-filename,
      importar_clientes,
      criar_funcionario,
      modificar_funcionario IMPORTING iv_id_funcionario TYPE zform16_func_t-id_funcionario,
      remover_funcionario IMPORTING iv_id_funcionario TYPE zform16_func_t-id_funcionario,
      criar_subscricao,
      modificar_subscricao IMPORTING iv_id_subscricao TYPE zform16_sub_t-id_subscricao,
      remover_subscricao IMPORTING iv_id_subscricao TYPE zform16_sub_t-id_subscricao,
      selecionar_por_subscricao IMPORTING iv_id_sub TYPE zform16_sub_t-id_subscricao EXPORTING et_cliente TYPE table_cliente,
      sap_script_por_subscricao IMPORTING it_cliente TYPE table_cliente,
      adobe,
      get_clientes_ativos EXPORTING et_cliente TYPE zform16_client_tt,
      smart_form IMPORTING iv_id_cliente TYPE zform16_client_t-id_cliente,
      upload_bmp IMPORTING iv_file_name  TYPE rlgrap-filename
                           iv_id_cliente TYPE zform16_client_t-id_cliente
                 EXPORTING ev_status     TYPE i.


  PRIVATE SECTION.

    METHODS:  get_logs,
      get_data,
      get_fieldcat,
      get_user_name EXPORTING ev_user_name TYPE string.

ENDCLASS.

CLASS lcl_ginasio IMPLEMENTATION.

  METHOD init.

    get_logs( ).
    get_fieldcat( ).
    get_data( ).
    CALL SCREEN 100.

  ENDMETHOD.

  METHOD get_logs.

    DATA: st_login TYPE zform16_logs_t.
    DATA: v_username TYPE string.

    get_user_name( IMPORTING ev_user_name = v_username ).

    st_login-username = sy-uname.
    st_login-data = sy-datum.
    st_login-hora = sy-uzeit.
    st_login-name = v_username.

    MODIFY zform16_logs_t FROM st_login.
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD get_data.

    SELECT * FROM zform16_client_t
      INTO TABLE gt_data_cliente.

    SELECT * FROM zform16_func_t
      INTO TABLE gt_data_funcionario.

    SELECT * FROM zform16_sub_t
      INTO TABLE gt_data_subscricao.

    SELECT * FROM zform16_logs_t
      INTO TABLE gt_data_logs.

  ENDMETHOD.

  METHOD get_fieldcat.

    DATA: gt_local_fieldcat_cliente     TYPE lvc_t_fcat,
          gt_local_fieldcat_funcionario TYPE lvc_t_fcat,
          gt_local_fieldcat_subscricao  TYPE lvc_t_fcat,
          gt_local_fieldcat_logs        TYPE lvc_t_fcat.


    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZFORM16_CLIENT_T'
      CHANGING
        ct_fieldcat            = gt_local_fieldcat_cliente
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE 'ERRO NO FIELDCAT' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      IF gt_local_fieldcat_cliente IS NOT INITIAL.
        gt_fieldcat_cliente = gt_local_fieldcat_cliente[].
      ENDIF.
    ENDIF.



    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZFORM16_FUNC_T'
      CHANGING
        ct_fieldcat            = gt_local_fieldcat_funcionario
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE 'ERRO NO FIELDCAT' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      IF gt_local_fieldcat_funcionario IS NOT INITIAL.
        gt_fieldcat_funcionario = gt_local_fieldcat_funcionario[].
      ENDIF.
    ENDIF.



    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZFORM16_SUB_T'
      CHANGING
        ct_fieldcat            = gt_local_fieldcat_subscricao
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE 'ERRO NO FIELDCAT' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      IF gt_local_fieldcat_subscricao IS NOT INITIAL.
        gt_fieldcat_subscricao = gt_local_fieldcat_subscricao[].
      ENDIF.
    ENDIF.



    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZFORM16_LOGS_T'
      CHANGING
        ct_fieldcat            = gt_local_fieldcat_logs
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE 'ERRO NO FIELDCAT' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.
      IF gt_local_fieldcat_logs IS NOT INITIAL.
        gt_fieldcat_logs = gt_local_fieldcat_logs[].
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD criar_cliente.

    DATA: v_max_id_cliente          TYPE int4,
          st_cliente                TYPE zform16_client_t,
          gt_fields                 TYPE STANDARD TABLE OF sval,
          v_returncode              TYPE c,
          v_id_cliente_string       TYPE string,
          v_file_name               TYPE rlgrap-filename,
          ans                       TYPE char10,
          st_subscricoes            TYPE zform16_sub_t,
          v_id_subscricao_submetido TYPE zform16_sub_t-id_subscricao,
          v_status                  TYPE i.

    SELECT MAX( id_cliente )
      FROM zform16_client_t
      INTO v_max_id_cliente.

    IF sy-subrc <> 0.
      v_max_id_cliente = -1.
    ELSEIF v_max_id_cliente IS INITIAL.
      v_max_id_cliente = 1.
    ELSE.
      v_max_id_cliente = v_max_id_cliente + 1.
    ENDIF.

    IF v_max_id_cliente <> -1.
      st_cliente-id_cliente = v_max_id_cliente.

      gt_fields = VALUE #( BASE gt_fields
                           ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'NOME'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'NIF'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'TELEFONE'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'EMAIL'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'MORADA'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'DATA_NASCIMENTO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'GENERO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'ID_SUBSCRICAO'
                             field_obl = abap_false ) ).

      v_id_cliente_string = v_max_id_cliente.
      CONCATENATE 'Dados para a inser????o do novo cliente com o ID ' v_id_cliente_string
              INTO DATA(titulo) SEPARATED BY space.

      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
*         NO_VALUE_CHECK  = ' '
          popup_title     = titulo
          start_column    = '5'
          start_row       = '5'
        IMPORTING
          returncode      = v_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
      ENDIF.

      IF v_returncode = 'A'.
        RETURN.
      ENDIF.

      IF gt_fields[ 8 ]-value <> ''.
        v_id_subscricao_submetido = gt_fields[ 8 ]-value.

        SELECT SINGLE *
          FROM zform16_sub_t
          INTO st_subscricoes
          WHERE id_subscricao = v_id_subscricao_submetido.

        IF st_subscricoes IS INITIAL AND gt_fields[ 8 ]-value <> ''.
          MESSAGE 'Adi????o de cliente cancelada. ID de subscri????o inexistente.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.

      IF gt_fields[ 6 ]-value > sy-datum.
        MESSAGE 'A data de nascimento n??o pode ser no futuro ;D.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      DATA(l_msg) = 'Adi????o de foto'.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = l_msg
          text_question         = 'Pretendes adicionar uma foto ao cliente criado? S?? podera ser do tipo "bmp".'
          text_button_1         = 'Sim'(002)
          text_button_2         = 'N??o'(005)
          default_button        = '1'
          display_cancel_button = ''
        IMPORTING
          answer                = ans.

      IF ans = 1.
        CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
          EXPORTING
            static    = 'X'
          CHANGING
            file_name = v_file_name.

        IF sy-subrc <> 0.
          MESSAGE i531(0u) WITH 'Ocorreu um erro a encontrar o caminho para a foto inserida'.
        ELSE.
          upload_bmp( EXPORTING iv_file_name = v_file_name
                                iv_id_cliente = st_cliente-id_cliente
                      IMPORTING ev_status = v_status ).
          IF v_status = 1.
            st_cliente-foto = 'imagem__cliente_' && v_max_id_cliente.
          ENDIF.
        ENDIF.
      ENDIF.

      IF gt_fields[ 1 ]-value <> ''.
        st_cliente-nome = gt_fields[ 1 ]-value.
      ENDIF.
      IF gt_fields[ 2 ]-value <> ''.
        st_cliente-nif = gt_fields[ 2 ]-value.
      ENDIF.
      IF gt_fields[ 3 ]-value <> ''.
        st_cliente-telefone = gt_fields[ 3 ]-value.
      ENDIF.
      IF gt_fields[ 4 ]-value <> ''.
        st_cliente-email = gt_fields[ 4 ]-value.
      ENDIF.
      IF gt_fields[ 5 ]-value <> ''.
        st_cliente-morada = gt_fields[ 5 ]-value.
      ENDIF.
      IF gt_fields[ 6 ]-value <> ''.
        st_cliente-data_nascimento = gt_fields[ 6 ]-value.
      ENDIF.
      IF gt_fields[ 7 ]-value <> ''.
        st_cliente-genero = gt_fields[ 7 ]-value.
      ENDIF.
      IF gt_fields[ 8 ]-value <> ''.
        st_cliente-id_subscricao = gt_fields[ 8 ]-value.
      ENDIF.

      SELECT SINGLE *
        FROM zform16_sub_t
        INTO st_subscricoes
        WHERE id_subscricao = v_id_subscricao_submetido.

      IF st_subscricoes IS INITIAL AND gt_fields[ 8 ]-value <> ''.
        MESSAGE 'ID de subscri????o inexistente.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      INSERT zform16_client_t FROM st_cliente.
      COMMIT WORK AND WAIT.
      IF sy-subrc = 0.
        IF v_status = 1.
        CONCATENATE 'Novo cliente com o ID' v_id_cliente_string 'criado com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
        MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.
        ELSE.
          CONCATENATE 'Novo cliente com o ID' v_id_cliente_string 'criado com sucesso por??m sem foto devido a ser muito grande.' INTO v_mensagem SEPARATED BY space.
        MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.
        ENDIF.
        APPEND st_cliente TO gt_data_cliente.
        IF sy-subrc <> 0.
          MESSAGE i531(0u) WITH 'Ocorreu um erro a atualizar a ALV.'.
        ENDIF.
      ELSE.
        MESSAGE i531(0u) WITH 'Ocorreu algum erro a inserir o novo cliente na base de dados.'.
      ENDIF.

    ELSE.
      MESSAGE 'Ocorreu algum erro a selecionar o id do cliente.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.

  ENDMETHOD.


  METHOD modificar_cliente.

    DATA: st_cliente TYPE zform16_client_t.

    SELECT SINGLE *
      FROM zform16_client_t
      INTO st_cliente
      WHERE id_cliente = iv_id_cliente.


    IF st_cliente IS INITIAL.
      MESSAGE 'ID de cliente inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.


      DATA: gt_fields                 TYPE STANDARD TABLE OF sval,
            v_returncode              TYPE c,
            v_vbeln                   TYPE vbak-vbeln,
            v_id_cliente_string       TYPE string,
            n_modificacoes            TYPE int2,
            n_modificacoes_string     TYPE string,
            st_subscricoes            TYPE zform16_sub_t,
            v_id_subscricao_submetido TYPE zform16_sub_t-id_subscricao.


      gt_fields = VALUE #( BASE gt_fields
                           ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'NOME'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'NIF'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'TELEFONE'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'EMAIL'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'MORADA'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'DATA_NASCIMENTO'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'GENERO'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_CLIENT_T'
                             fieldname = 'ID_SUBSCRICAO'
                             field_obl = abap_false ) ).

      v_id_cliente_string = iv_id_cliente.
      CONCATENATE 'Modificar cliente com o ID ' v_id_cliente_string
              INTO DATA(titulo) SEPARATED BY space.

      n_modificacoes = 0.

      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
*         NO_VALUE_CHECK  = ' '
          popup_title     = titulo
          start_column    = '5'
          start_row       = '5'
        IMPORTING
          returncode      = v_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
      ENDIF.

      IF v_returncode = 'A'.
        RETURN.
      ENDIF.

      IF gt_fields[ 8 ]-value <> ''.
        v_id_subscricao_submetido = gt_fields[ 8 ]-value.

        SELECT SINGLE *
            FROM zform16_sub_t
            INTO st_subscricoes
            WHERE id_subscricao = v_id_subscricao_submetido.

        IF st_subscricoes IS INITIAL.
          MESSAGE 'Modifica????o cancelada. ID de subscri????o inexistente.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.

      IF gt_fields[ 6 ]-value > sy-datum AND gt_fields[ 6 ]-value <> ''.
        MESSAGE 'A data de nascimento n??o pode ser no futuro ;D.' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.


      LOOP AT gt_fields INTO DATA(st_fields).
        IF st_fields-value <> ''.
          n_modificacoes = n_modificacoes + 1.
        ENDIF.
      ENDLOOP.

      IF n_modificacoes = 0.
        MESSAGE i531(0u) WITH 'Nenhum valor foi alterado'.
      ELSE.
        IF gt_fields[ 1 ]-value <> ''.
          st_cliente-nome = gt_fields[ 1 ]-value.
        ENDIF.
        IF gt_fields[ 2 ]-value <> ''.
          st_cliente-nif = gt_fields[ 2 ]-value.
        ENDIF.
        IF gt_fields[ 3 ]-value <> ''.
          st_cliente-telefone = gt_fields[ 3 ]-value.
        ENDIF.
        IF gt_fields[ 4 ]-value <> ''.
          st_cliente-email = gt_fields[ 4 ]-value.
        ENDIF.
        IF gt_fields[ 5 ]-value <> ''.
          st_cliente-morada = gt_fields[ 5 ]-value.
        ENDIF.
        IF gt_fields[ 6 ]-value <> ''.
          st_cliente-data_nascimento = gt_fields[ 6 ]-value.
        ENDIF.
        IF gt_fields[ 7 ]-value <> ''.
          st_cliente-genero = gt_fields[ 7 ]-value.
        ENDIF.
        IF gt_fields[ 8 ]-value <> ''.
          st_cliente-id_subscricao = gt_fields[ 8 ]-value.
        ENDIF.

        UPDATE zform16_client_t FROM st_cliente.
        IF sy-subrc = 0.
          n_modificacoes_string = n_modificacoes.
          CONCATENATE n_modificacoes_string 'campos alterados com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
          MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.

          SELECT * FROM zform16_client_t
            INTO TABLE gt_data_cliente.

        ELSE.
          MESSAGE i531(0u) WITH 'Ocorreu algum erro a dar update na base de dados do cliente pretendido.'.
        ENDIF.
      ENDIF.

    ENDIF.


  ENDMETHOD.

  METHOD remover_cliente.

    DATA: st_cliente TYPE zform16_client_t.

    SELECT SINGLE *
      FROM zform16_client_t
      INTO st_cliente
      WHERE id_cliente = iv_id_cliente.

    IF st_cliente IS INITIAL.
      MESSAGE 'ID de cliente inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      DELETE FROM zform16_client_t WHERE id_cliente = iv_id_cliente.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.
        MESSAGE 'Cliente removido com sucesso' TYPE 'S' DISPLAY LIKE 'S'.

        SELECT * FROM zform16_client_t
        INTO TABLE gt_data_cliente.

      ELSE.
        MESSAGE 'Houve um problema a remover o cliente na base de dados' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD criar_funcionario.

    DATA: v_max_id_funcionario    TYPE int4,
          st_funcionario          TYPE zform16_func_t,
          gt_fields               TYPE STANDARD TABLE OF sval,
          v_returncode            TYPE c,
          v_id_funcionario_string TYPE string,
          v_data_atual            TYPE dats.

    SELECT MAX( id_funcionario )
      FROM zform16_func_t
      INTO v_max_id_funcionario.

    IF sy-subrc <> 0.
      v_max_id_funcionario = -1.
    ELSEIF v_max_id_funcionario IS INITIAL.
      v_max_id_funcionario = 1.
    ELSE.
      v_max_id_funcionario = v_max_id_funcionario + 1.
    ENDIF.

    IF v_max_id_funcionario <> -1.
      st_funcionario-id_funcionario = v_max_id_funcionario.

      gt_fields = VALUE #( BASE gt_fields
                           ( tabname   = 'ZFORM16_FUNC_T'
                             fieldname = 'NOME'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_FUNC_T'
                             fieldname = 'ORDENADO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_FUNC_T'
                             fieldname = 'INICIO_CONTRATO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_FUNC_T'
                             fieldname = 'FIM_CONTRATO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_FUNC_T'
                             fieldname = 'FUNCAO'
                             field_obl = abap_true ) ).

      v_id_funcionario_string = v_max_id_funcionario.
      CONCATENATE 'Dados para a inser????o do novo funcion??rio com o ID ' v_id_funcionario_string
              INTO DATA(titulo) SEPARATED BY space.

      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
*         NO_VALUE_CHECK  = ' '
          popup_title     = titulo
          start_column    = '5'
          start_row       = '5'
        IMPORTING
          returncode      = v_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
      ENDIF.

      IF v_returncode = 'A'.
        RETURN.
      ENDIF.

      IF gt_fields[ 2 ]-value <= 100.
        MESSAGE 'O funcion??rio precisa de ter o ordenado no min??mo 100 euros.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 4 ]-value <= gt_fields[ 3 ]-value.
        MESSAGE 'O in??cio de contrato precisa de ser antes do fim de contrato.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      v_data_atual = sy-datum.

      IF gt_fields[ 4 ]-value <= v_data_atual.
        MESSAGE 'O fim de contrato precisa de ser depois da data atual.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 4 ]-value <= v_data_atual.
        MESSAGE 'O in??cio de contrato precisa de ser depois da data atual.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 1 ]-value <> ''.
        st_funcionario-nome = gt_fields[ 1 ]-value.
      ENDIF.
      IF gt_fields[ 2 ]-value <> ''.
        st_funcionario-ordenado = gt_fields[ 2 ]-value.
      ENDIF.
      IF gt_fields[ 3 ]-value <> ''.
        st_funcionario-inicio_contrato = gt_fields[ 3 ]-value.
      ENDIF.
      IF gt_fields[ 4 ]-value <> ''.
        st_funcionario-fim_contrato = gt_fields[ 4 ]-value.
      ENDIF.
      IF gt_fields[ 5 ]-value <> ''.
        st_funcionario-funcao = gt_fields[ 5 ]-value.
      ENDIF.

      INSERT zform16_func_t FROM st_funcionario.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.

        CONCATENATE 'Novo funcion??rio com o ID' v_id_funcionario_string 'criado com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
        MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.
        APPEND st_funcionario TO gt_data_funcionario.

        IF sy-subrc <> 0.
          MESSAGE i531(0u) WITH 'Ocorreu um erro a atualizar a ALV.'.
        ENDIF.
      ELSE.
        MESSAGE i531(0u) WITH 'Ocorreu algum erro a inserir o novo funcion??rio na base de dados.'.
      ENDIF.

    ELSE.
      MESSAGE 'Ocorreu algum erro a selecionar o id do funcion??rio.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.


  ENDMETHOD.


  METHOD modificar_funcionario.

    DATA:gt_fields               TYPE STANDARD TABLE OF sval,
         v_returncode            TYPE c,
         v_id_funcionario_string TYPE string,
         n_modificacoes          TYPE int2,
         n_modificacoes_string   TYPE string,
         st_funcionario          TYPE zform16_func_t,
         v_data_atual            TYPE dats.

    SELECT SINGLE *
      FROM zform16_func_t
      INTO st_funcionario
      WHERE id_funcionario = iv_id_funcionario.

    IF st_funcionario IS INITIAL.
      MESSAGE 'ID de funcion??rio inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      gt_fields = VALUE #( BASE gt_fields
                             ( tabname   = 'ZFORM16_FUNC_T'
                               fieldname = 'NOME'
                               field_obl = abap_false )
                               ( tabname   = 'ZFORM16_FUNC_T'
                               fieldname = 'ORDENADO'
                               field_obl = abap_false )
                               ( tabname   = 'ZFORM16_FUNC_T'
                               fieldname = 'INICIO_CONTRATO'
                               field_obl = abap_false )
                               ( tabname   = 'ZFORM16_FUNC_T'
                               fieldname = 'FIM_CONTRATO'
                               field_obl = abap_false )
                               ( tabname   = 'ZFORM16_FUNC_T'
                               fieldname = 'FUNCAO'
                               field_obl = abap_false ) ).

      v_id_funcionario_string = iv_id_funcionario.
      v_data_atual = sy-datum.
      CONCATENATE 'Modificar funcion??rio com o ID ' v_id_funcionario_string
              INTO DATA(titulo) SEPARATED BY space.


      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
*         NO_VALUE_CHECK  = ' '
          popup_title     = titulo
          start_column    = '5'
          start_row       = '5'
        IMPORTING
          returncode      = v_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
      ENDIF.

      IF v_returncode = 'A'.
        RETURN.
      ENDIF.

      IF gt_fields[ 2 ]-value <= 100 AND gt_fields[ 2 ]-value <> ''.
        MESSAGE 'O funcion??rio precisa de ter o ordenado no min??mo de 100 euros.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      "ENDIF.

      ELSEIF gt_fields[ 4 ]-value <= gt_fields[ 3 ]-value AND gt_fields[ 4 ]-value <> '' AND gt_fields[ 3 ]-value <> ''.
        MESSAGE 'O in??cio de contrato precisa de ser antes do fim de contrato.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      "ENDIF.

      v_data_atual = sy-datum.

      ELSEIF gt_fields[ 4 ]-value <= v_data_atual AND gt_fields[ 4 ]-value <> ''.
        MESSAGE 'O fim de contrato precisa de ser depois da data atual.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      "ENDIF.

      ELSEIF gt_fields[ 4 ]-value <= st_funcionario-inicio_contrato AND gt_fields[ 4 ]-value <> '' AND gt_fields[ 3 ]-value = ''.
        MESSAGE 'O fim de contrato precisa de ser depois da data do in??cio de contrato.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      "ENDIF.

      ELSEIF gt_fields[ 3 ]-value < v_data_atual AND gt_fields[ 3 ]-value <> ''.
        MESSAGE 'O in??cio de contrato precisa de ser hoje ou depois do dia de hoje.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      "ENDIF.

      ELSEIF gt_fields[ 3 ]-value >= st_funcionario-fim_contrato AND gt_fields[ 3 ]-value <> '' AND gt_fields[ 4 ]-value = ''.
        MESSAGE 'O in??cio de contrato precisa de ser antes do fim de contrato.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      n_modificacoes = 0.
      LOOP AT gt_fields INTO DATA(st_fields).
        IF st_fields-value <> ''.
          n_modificacoes = n_modificacoes + 1.
        ENDIF.
      ENDLOOP.

      IF n_modificacoes = 0.
        MESSAGE i531(0u) WITH 'Nenhum valor foi alterado'.
      ELSE.
        IF gt_fields[ 1 ]-value <> ''.
          st_funcionario-nome = gt_fields[ 1 ]-value.
        ENDIF.
        IF gt_fields[ 2 ]-value <> ''.
          st_funcionario-ordenado = gt_fields[ 2 ]-value.
        ENDIF.
        IF gt_fields[ 3 ]-value <> ''.
          st_funcionario-inicio_contrato = gt_fields[ 3 ]-value.
        ENDIF.
        IF gt_fields[ 4 ]-value <> ''.
          st_funcionario-fim_contrato = gt_fields[ 4 ]-value.
        ENDIF.
        IF gt_fields[ 5 ]-value <> ''.
          st_funcionario-funcao = gt_fields[ 5 ]-value.
        ENDIF.

        UPDATE zform16_func_t FROM st_funcionario.
        IF sy-subrc = 0.
          n_modificacoes_string = n_modificacoes.
          CONCATENATE n_modificacoes_string 'campos alterados com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
          MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.
          SELECT * FROM zform16_func_t
            INTO TABLE gt_data_funcionario.

          SELECT * FROM zform16_func_t
            INTO TABLE gt_data_funcionario.

        ELSE.
          MESSAGE i531(0u) WITH 'Ocorreu algum erro a dar update na base de dados do cliente pretendido.'.
        ENDIF.
      ENDIF.

    ENDIF.

  ENDMETHOD.


  METHOD remover_funcionario.

    DATA: st_funcionario TYPE zform16_func_t.

    SELECT SINGLE *
      FROM zform16_func_t
      INTO st_funcionario
      WHERE id_funcionario = iv_id_funcionario.

    IF st_funcionario IS INITIAL.
      MESSAGE 'ID de funcion??rio inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      DELETE FROM zform16_func_t WHERE id_funcionario = iv_id_funcionario.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.
        MESSAGE 'Funcion??rio removido com sucesso' TYPE 'S' DISPLAY LIKE 'S'.
        SELECT * FROM zform16_func_t
        INTO TABLE gt_data_funcionario.

      ELSE.
        MESSAGE 'Houve um problema a remover o funcion??rio na base de dados' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    ENDIF.


  ENDMETHOD.

  METHOD criar_subscricao.

    DATA: v_max_id_subscricao    TYPE int4,
          st_subscricao          TYPE zform16_sub_t,
          gt_fields              TYPE STANDARD TABLE OF sval,
          v_returncode           TYPE c,
          v_id_subscricao_string TYPE string,
          v_data_atual           TYPE dats.

    SELECT MAX( id_subscricao )
      FROM zform16_sub_t
      INTO v_max_id_subscricao.

    IF sy-subrc <> 0.
      v_max_id_subscricao = -1.
    ELSEIF v_max_id_subscricao IS INITIAL.
      v_max_id_subscricao = 1.
    ELSE.
      v_max_id_subscricao = v_max_id_subscricao + 1.
    ENDIF.

    IF v_max_id_subscricao <> -1.
      st_subscricao-id_subscricao = v_max_id_subscricao.

      gt_fields = VALUE #( BASE gt_fields
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'IS_LIVRE'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'VALOR'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'DATA_EXPIRACAO'
                             field_obl = abap_true )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'DESCRICAO'
                             field_obl = abap_true )
                             ).

      v_id_subscricao_string = v_max_id_subscricao.
      CONCATENATE 'Dados para a inser????o da nova subscri????o com o ID ' v_id_subscricao_string
              INTO DATA(titulo) SEPARATED BY space.

      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
*         NO_VALUE_CHECK  = ' '
          popup_title     = titulo
          start_column    = '5'
          start_row       = '5'
        IMPORTING
          returncode      = v_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.

      IF sy-subrc <> 0.
        MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
      ENDIF.

      IF v_returncode = 'A'.
        RETURN.
      ENDIF.

      v_data_atual = sy-datum.

      IF gt_fields[ 3 ]-value <> '' AND gt_fields[ 3 ]-value < v_data_atual.
        MESSAGE 'Inser????o cancelada. A data de experi????o s?? poder?? ser posterior ?? data atual.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 2 ]-value <> '' AND gt_fields[ 2 ]-value <= 0.
        MESSAGE 'Inser????o cancelada. O valor tem de ser positivo.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 1 ]-value <> ''.
        st_subscricao-is_livre = gt_fields[ 1 ]-value.
      ENDIF.
      IF gt_fields[ 2 ]-value <> ''.
        st_subscricao-valor = gt_fields[ 2 ]-value.
      ENDIF.
      IF gt_fields[ 3 ]-value <> ''.
        st_subscricao-data_expiracao = gt_fields[ 3 ]-value.
      ENDIF.
      IF gt_fields[ 4 ]-value <> ''.
        st_subscricao-descricao = gt_fields[ 4 ]-value.
      ENDIF.


      INSERT zform16_sub_t FROM st_subscricao.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.

        CONCATENATE 'Nova subscri????o com o ID' v_id_subscricao_string 'criado com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
        MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.
        APPEND st_subscricao TO gt_data_subscricao.

        IF sy-subrc <> 0.
          MESSAGE i531(0u) WITH 'Ocorreu um erro a atualizar a ALV.'.
        ENDIF.
      ELSE.
        MESSAGE i531(0u) WITH 'Ocorreu algum erro a inserir a nova subscri????o na base de dados.'.
      ENDIF.

    ELSE.
      MESSAGE 'Ocorreu algum erro a selecionar o id da subscri????o.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.


  ENDMETHOD.


  METHOD modificar_subscricao.

    DATA: st_subscricao          TYPE zform16_sub_t,
          gt_fields              TYPE STANDARD TABLE OF sval,
          v_returncode           TYPE c,
          v_id_subscricao_string TYPE string,
          n_modificacoes         TYPE int2,
          n_modificacoes_string  TYPE string,
          v_data_atual           TYPE dats.





    gt_fields = VALUE #( BASE gt_fields
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'IS_LIVRE'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'VALOR'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'DATA_EXPIRACAO'
                             field_obl = abap_false )
                             ( tabname   = 'ZFORM16_SUB_T'
                             fieldname = 'DESCRICAO'
                             field_obl = abap_false )
                             ).

    v_id_subscricao_string = iv_id_subscricao.
    CONCATENATE 'Modificar funcion??rio com o ID ' v_id_subscricao_string
            INTO DATA(titulo) SEPARATED BY space.

    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
*       NO_VALUE_CHECK  = ' '
        popup_title     = titulo
        start_column    = '5'
        start_row       = '5'
      IMPORTING
        returncode      = v_returncode
      TABLES
        fields          = gt_fields
      EXCEPTIONS
        error_in_fields = 1
        OTHERS          = 2.

    IF sy-subrc <> 0.
      MESSAGE i531(0u) WITH 'Problema com a fun????o POPUP_GET_VALUES'.
    ENDIF.

    IF v_returncode = 'A'.
      RETURN.
    ENDIF.

    SELECT                 SINGLE *
                    FROM zform16_sub_t
                    INTO st_subscricao
                    WHERE id_subscricao = iv_id_subscricao.

    IF st_subscricao IS INITIAL AND gt_fields[ 4 ]-value <> ''.
      MESSAGE 'ID de subscri????o inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      v_data_atual = sy-datum.

      IF gt_fields[ 3 ]-value <> '' AND gt_fields[ 3 ]-value < v_data_atual.
        MESSAGE 'Modifica????o cancelada. A data de experi????o s?? poder?? ser posterior ?? data atual.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gt_fields[ 2 ]-value <> '' AND gt_fields[ 2 ]-value <= 0.
        MESSAGE 'Inser????o cancelada. O valor tem de ser maior que 1 euro.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      n_modificacoes = 0.
      LOOP AT gt_fields INTO DATA(st_fields).
        IF st_fields-value <> ''.
          n_modificacoes = n_modificacoes + 1.
        ENDIF.
      ENDLOOP.

      IF n_modificacoes = 0.
        MESSAGE i531(0u) WITH 'Nenhum valor foi alterado'.
      ELSE.
        IF gt_fields[ 1 ]-value <> ''.
          st_subscricao-is_livre = gt_fields[ 1 ]-value.
        ENDIF.
        IF gt_fields[ 2 ]-value <> ''.
          st_subscricao-valor = gt_fields[ 2 ]-value.
        ENDIF.
        IF gt_fields[ 3 ]-value <> ''.
          st_subscricao-data_expiracao = gt_fields[ 3 ]-value.
        ENDIF.
        IF gt_fields[ 4 ]-value <> ''.
          st_subscricao-descricao = gt_fields[ 4 ]-value.
        ENDIF.

        UPDATE zform16_sub_t FROM st_subscricao.
        IF sy-subrc = 0.
          n_modificacoes_string = n_modificacoes.
          CONCATENATE n_modificacoes_string 'campos alterados com sucesso.' INTO DATA(v_mensagem) SEPARATED BY space.
          MESSAGE v_mensagem TYPE 'S' DISPLAY LIKE 'S'.

          SELECT * FROM zform16_sub_t
            INTO TABLE gt_data_subscricao.

        ELSE.
          MESSAGE i531(0u) WITH 'Ocorreu algum erro a dar update na base de dados da subscri????o pretendido.'.
        ENDIF.
      ENDIF.

      MODIFY zform16_sub_t FROM st_subscricao.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.
        MESSAGE 'Subscri????o modificado com sucesso' TYPE 'S' DISPLAY LIKE 'S'.
      ELSE.
        MESSAGE 'Houve um problema a modificar a subscri????o na base de dados' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    ENDIF.

  ENDMETHOD.
  METHOD remover_subscricao.

    DATA: st_subscricao TYPE zform16_sub_t.

    SELECT SINGLE *
      FROM zform16_sub_t
      INTO st_subscricao
      WHERE id_subscricao = iv_id_subscricao.

    IF st_subscricao IS INITIAL.
      MESSAGE 'ID de subscri????o inexistente' TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      DELETE FROM zform16_sub_t WHERE id_subscricao = iv_id_subscricao.
      COMMIT WORK AND WAIT.

      IF sy-subrc = 0.
        MESSAGE 'Subscri????o removida com sucesso' TYPE 'S' DISPLAY LIKE 'S'.
        SELECT * FROM zform16_sub_t
            INTO TABLE gt_data_subscricao.
      ELSE.
        MESSAGE 'Houve um problema a remover a subscri????o na base de dados' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD importar_clientes.

    DATA: lv_filename            TYPE string,
          gt_clientes_upload     TYPE TABLE OF zform16_client_t,
          st_clientes_upload     TYPE zform16_client_t,
          gt_txt                 TYPE TABLE OF ty_txt,
          v_id_cliente_string    TYPE string,
          v_id_subscricao_string TYPE string,
          v_file                 TYPE rlgrap-filename.


    CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
      EXPORTING
        mask      = '*.txt'
        static    = 'X'
      CHANGING
        file_name = v_file.

    lv_filename = v_file.

    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = lv_filename
      TABLES
        data_tab                = gt_txt
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    LOOP AT gt_txt INTO DATA(gs_txt).

      SPLIT gs_txt-campo AT ';'
       INTO v_id_cliente_string
            st_clientes_upload-nif
            st_clientes_upload-nome
            st_clientes_upload-telefone
            st_clientes_upload-email
            st_clientes_upload-morada
            st_clientes_upload-data_nascimento
            st_clientes_upload-foto
            st_clientes_upload-genero
            v_id_subscricao_string.

      st_clientes_upload-id_cliente = v_id_cliente_string.
      st_clientes_upload-id_subscricao = v_id_subscricao_string.

      APPEND st_clientes_upload TO gt_clientes_upload.
      CLEAR st_clientes_upload.

      gt_data_cliente = gt_clientes_upload.

    ENDLOOP.

  ENDMETHOD.

  METHOD exportar_clientes.

    DATA:
      lv_filename            TYPE string,
      v_id_cliente_string    TYPE string,
      v_id_subscricao_string TYPE string,
      st_txt                 TYPE ty_txt,
      gt_txt                 TYPE TABLE OF ty_txt.


    LOOP AT gt_data_cliente INTO DATA(st_data_clientes).

      v_id_cliente_string = st_data_clientes-id_cliente.
      v_id_subscricao_string = st_data_clientes-id_subscricao.

      CONCATENATE v_id_cliente_string
            st_data_clientes-nif
            st_data_clientes-nome
            st_data_clientes-telefone
            st_data_clientes-email
            st_data_clientes-morada
            st_data_clientes-data_nascimento
            st_data_clientes-foto
            st_data_clientes-genero
            v_id_subscricao_string
      INTO st_txt-campo SEPARATED BY ';'.

      APPEND st_txt TO gt_txt.
      CLEAR st_txt.

    ENDLOOP.

    lv_filename = iv_file && '.txt'.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
*       BIN_FILESIZE            =
        filename                = lv_filename
*       FILETYPE                = 'ASC'
*       APPEND                  = ' '
        write_field_separator   = 'X'
      TABLES
        data_tab                = gt_txt
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.

    IF sy-subrc = 0.
      MESSAGE s000(zmsg) WITH 'Arquivo gerado com sucesso.'.
    ELSE.
      MESSAGE s000(zmsg) WITH 'Houve um problema na gera????o do arquivo para o computador'.
    ENDIF.

  ENDMETHOD.

  METHOD selecionar_por_subscricao.

    SELECT *
      FROM zform16_client_t
      WHERE id_subscricao = @iv_id_sub
      INTO TABLE @DATA(gt_cliente).

    IF sy-subrc IS NOT INITIAL.
      MESSAGE i531(0u) WITH 'N??o existem clientes com o id de subscri????o pretendido.'.
      RETURN.
    ELSE.
      et_cliente = gt_cliente[].
    ENDIF.

  ENDMETHOD.

  METHOD sap_script_por_subscricao.

    DATA: v_cont(2)            TYPE n,
          v_id_subscricao      TYPE zform16_client_t-id_subscricao,
          gt_saida             TYPE TABLE OF zform16_client_t,
          v_id_string          TYPE string,
          v_contador(3)        TYPE n,
          v_lenght_nome        TYPE i,
          v_lenght_id_cliente  TYPE i,
          v_lenght_telefone    TYPE i,
          v_lenght_email       TYPE i,
          v_lenght_morada      TYPE i,
*          spaces_ate_nome(3)     TYPE n,
*          spaces_ate_telefone(3) TYPE n,
*          spaces_ate_email(3)    TYPE n,
*          spaces_ate_morada(3)   TYPE n,
          v_temp_spaces(3)     TYPE n,
          v_spaces_total(3)    TYPE n,
          v_spaces_nome(3)     TYPE n,
          v_spaces_telefone(3) TYPE n,
          v_spaces_email(3)    TYPE n, "string,
          v_spaces_morada(3)   TYPE n. "string.

    CALL FUNCTION 'OPEN_FORM'
      EXPORTING
        form                        = 'ZFORM16_SP'
      EXCEPTIONS
        canceled                    = 1
        device                      = 2
        form                        = 3
        options                     = 4
        unclosed                    = 5
        mail_options                = 6
        archive_error               = 7
        invalid_fax_number          = 8
        more_params_needed_in_batch = 9
        spool_error                 = 10
        codepage                    = 11
        OTHERS                      = 12.

    IF sy-subrc = 0.

      CALL FUNCTION 'START_FORM'
        EXPORTING
          form        = 'ZFORM16_SP'
        EXCEPTIONS
          form        = 1
          format      = 2
          unended     = 3
          unopened    = 4
          unused      = 5
          spool_error = 6
          codepage    = 7
          OTHERS      = 8.


      IF sy-subrc = 0.
        v_id_subscricao = it_cliente[ 1 ]-id_subscricao.

        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'HEADER'
            window  = 'DADOS'.

        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'LOGO'
            window  = 'LOGO'.


        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'HEADER_TABELA'
            window  = 'MAIN'.

        gt_saida = it_cliente[].

        LOOP AT gt_saida INTO st_saida_sp.
          v_spaces_nome = ''.
          v_contador = 0.
          v_cont = v_cont + 1.
          v_id_string = st_saida_sp-id_cliente.

          v_lenght_id_cliente = strlen( v_id_string ).
          v_lenght_nome = strlen( st_saida_sp-nome ).
          v_lenght_telefone = strlen( st_saida_sp-telefone ).
          v_lenght_email = strlen( st_saida_sp-email ).
          v_lenght_morada = strlen( st_saida_sp-morada ).

          v_sp = st_saida_sp-id_cliente.

          v_spaces_nome = 7 - v_lenght_id_cliente.
          IF v_spaces_nome <= 0.
            v_spaces_nome = 2.
            "LOGICA THEN SE ULTRAPASSAR DEFENIR LIMITES A CHECKAR NO SAP SCRIPT E SE PASSAR PRONTOS TRUNCAR O CAMPO
          ENDIF.

          v_spaces_total = v_spaces_nome.

          WHILE v_contador <> v_spaces_nome.
            v_sp = v_sp && ` `.
            v_contador = v_contador + 1.
          ENDWHILE.

          DATA(v_nome_condensado) = st_saida_sp-nome.
          CONDENSE v_nome_condensado.

*          CONCATENATE v_sp v_nome_condensado INTO v_sp RESPECTING BLANKS .
          CONCATENATE v_sp v_nome_condensado INTO v_sp.

          v_temp_spaces =  v_lenght_id_cliente + v_lenght_nome + v_contador.
          v_spaces_telefone = 27 - v_temp_spaces.

          IF v_spaces_telefone <= 0.
            v_spaces_telefone = 2.
          ENDIF.

          v_spaces_total = v_spaces_total + v_spaces_telefone.

          v_contador = 0.
          WHILE v_contador <> v_spaces_telefone.
            v_sp = v_sp && ` `.
            v_contador = v_contador + 1.
          ENDWHILE.

          DATA(v_telefone_condensado) = st_saida_sp-telefone.
          CONDENSE v_telefone_condensado.

          CONCATENATE v_sp v_telefone_condensado INTO v_sp.

          v_spaces_email = 37 - ( v_temp_spaces + v_spaces_telefone + v_lenght_telefone ).
          IF v_spaces_email <= 0.
            v_spaces_email = 2.
          ENDIF.
          v_contador = 0.
          v_spaces_total = v_spaces_total + v_spaces_email.

          IF v_spaces_total > 19 AND v_lenght_email < 13.
            v_spaces_email = v_spaces_email + 4.
          ENDIF.

          WHILE v_contador <> v_spaces_email.
            v_sp = v_sp && ` `.
            v_contador = v_contador + 1.
          ENDWHILE.

          DATA(v_email_condensado) = st_saida_sp-email.
          CONDENSE v_email_condensado.

          CONCATENATE v_sp v_email_condensado INTO v_sp.


          v_spaces_morada = 35 - ( v_temp_spaces + v_spaces_email + v_lenght_email ).
          IF v_spaces_morada <= 0.
            v_spaces_morada = 2.
          ENDIF.
          v_contador = 0.
          v_spaces_total = v_spaces_total + v_spaces_morada.

          IF v_spaces_total > 17 AND v_spaces_total < 20.
            v_spaces_morada = v_spaces_morada + 3.
          ENDIF.

          IF v_lenght_morada < 15.
            v_spaces_morada = v_spaces_morada + 5.
          ENDIF.
*          IF V_SPACES_TOTAL > 30 AND v_lenght_morada < 10.
*            V_SPACES_MORADA = V_SPACES_TOTAL + 2.
*          ENDIF.

          WHILE v_contador <> v_spaces_morada.
            v_sp = v_sp && ` `.
            v_contador = v_contador + 1.
          ENDWHILE.

          DATA(v_morada_condensado) = st_saida_sp-morada.
          CONDENSE v_morada_condensado.

          CONCATENATE v_sp v_morada_condensado INTO v_sp.

          CALL FUNCTION 'WRITE_FORM'
            EXPORTING
              element = 'TABELA'
              window  = 'MAIN'.

          IF v_cont = 25.

            CALL FUNCTION 'END_FORM'.
            CALL FUNCTION 'START_FORM'
              EXPORTING
                form = 'ZFORM16_SP'.

            CALL FUNCTION 'WRITE_FORM'
              EXPORTING
                element = 'HEADER'
                window  = 'DADOS'.


            CALL FUNCTION 'WRITE_FORM'
              EXPORTING
                element = 'LOGO'
                window  = 'LOGO'.


            CALL FUNCTION 'WRITE_FORM'
              EXPORTING
                element = 'HEADER_TABELA'
                window  = 'MAIN'.

            CALL FUNCTION 'WRITE_FORM'
              EXPORTING
                element = 'TABELA'
                window  = 'MAIN'.

            CLEAR v_cont.
          ENDIF.
        ENDLOOP.


        CALL FUNCTION 'END_FORM'
          EXCEPTIONS
            unopened                 = 1
            bad_pageformat_for_print = 2
            spool_error              = 3
            codepage                 = 4
            OTHERS                   = 5.

        CALL FUNCTION 'CLOSE_FORM'
          EXCEPTIONS
            unopened                 = 1
            bad_pageformat_for_print = 2
            send_error               = 3
            spool_error              = 4
            codepage                 = 5
            OTHERS                   = 6.
        IF sy-subrc <> 0.
        ENDIF.

      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD get_clientes_ativos.

    DATA: date TYPE dats.

    date = sy-datum.

    SELECT b~id_cliente, b~nif, b~nome, b~telefone, b~email, b~id_subscricao
      FROM zform16_sub_t AS a
      INNER JOIN zform16_client_t AS b
      ON a~id_subscricao = b~id_subscricao
      INTO TABLE @et_cliente
      WHERE a~data_expiracao > @date.

  ENDMETHOD.

  METHOD get_user_name.

    DATA: v_username TYPE string.


    CALL METHOD cl_gui_frontend_services=>get_user_name
      CHANGING
        user_name    = v_username
      EXCEPTIONS
        cntl_error   = 1
        error_no_gui = 2
        OTHERS       = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CALL METHOD cl_gui_cfw=>update_view
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2
        OTHERS            = 3.

    ev_user_name = v_username.

  ENDMETHOD.

  METHOD adobe.

    DATA: ls_sfpoutputparams TYPE sfpoutputparams,
          lv_mod_func        TYPE funcname,
          ls_docparams       TYPE sfpdocparams,
          gt_table_local     TYPE zform16_client_tt.

    get_clientes_ativos( IMPORTING et_cliente = gt_table_local ).

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = ls_sfpoutputparams
      EXCEPTIONS
        cancel          = 1
        usage_error     = 2
        system_error    = 3
        internal_error  = 4
        OTHERS          = 5.


    CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
      EXPORTING
        i_name     = 'ZFORM16_GYM_ADOBE'
      IMPORTING
        e_funcname = lv_mod_func.

    CALL FUNCTION lv_mod_func
      EXPORTING
        /1bcdwb/docparams = ls_docparams
        it_cliente        = gt_table_local
      EXCEPTIONS
        usage_error       = 1
        system_error      = 2
        internal_error    = 3
        OTHERS            = 4.

    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.


    CALL FUNCTION 'FP_JOB_CLOSE'
      EXCEPTIONS
        usage_error    = 1
        system_error   = 2
        internal_error = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  ENDMETHOD.


  METHOD smart_form.

    DATA: lv_fm_name TYPE rs38l_fnam,
          gt_data    TYPE zform16_client2_tt.

    SELECT id_cliente nif nome telefone email morada data_nascimento foto genero id_subscricao
      FROM zform16_client_t
      INTO TABLE gt_data
      WHERE id_cliente = iv_id_cliente.

    IF gt_data[ 1 ]-foto <> ''.
      v_diretorio_foto = 'imagem__cliente_' && iv_id_cliente.
    ELSE.
      v_diretorio_foto = 'GYM_COLORIDO2'.
    ENDIF.


    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = 'ZFORM16_GYM_SF'
      IMPORTING
        fm_name            = lv_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.

    IF sy-subrc = 0.

      CALL FUNCTION lv_fm_name
        EXPORTING
          iv_diretorio_foto = v_diretorio_foto
        TABLES
          gt_cliente_sf     = gt_data
        EXCEPTIONS
          formatting_error  = 1
          internal_error    = 2
          send_error        = 3
          user_canceled     = 4
          OTHERS            = 5.

      IF sy-subrc <> 0.

        MESSAGE s000(zmsg) WITH 'Erro ao imprimir formul??rio' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD upload_bmp.

    DATA: v_file_name        TYPE localfile,
          v_file_name_output TYPE stxbitmaps-tdname,
          v_id_cliente       TYPE zform16_client_t-id_cliente,
          v_tamanho_file     TYPE int4,
          v_titulo           TYPE bapisignat-prop_value,
          st_imagem          TYPE stxbitmaps.

    ev_status = 1.
    v_file_name_output = 'imagem__cliente_' && iv_id_cliente.
    v_file_name = iv_file_name.

    SUBMIT zbg16_cmon WITH p_file = v_file_name WITH p_image = v_file_name_output AND RETURN.
    COMMIT WORK AND WAIT.

    TRANSLATE v_file_name_output TO UPPER CASE.

    SELECT SINGLE *
      FROM stxbitmaps
      INTO st_imagem
      WHERE tdname = v_file_name_output.

    IF st_imagem-heighttw > 6000 OR st_imagem-widthtw > 6000.
      MESSAGE s000(zmsg) WITH 'A imagem tem de ser mais pequena, s?? pode ter 10cm x 10cm no m??ximo.' DISPLAY LIKE 'E'.
      WAIT UP TO '1' SECONDS.
      "logica para remover a imagem"
      DELETE stxbitmaps FROM st_imagem.
      COMMIT WORK AND WAIT.

      ev_status = 0.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
