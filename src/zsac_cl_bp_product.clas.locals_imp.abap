CLASS lhc_productvaluation DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ProductValuation RESULT result.

    METHODS AddStocks FOR MODIFY
      IMPORTING keys FOR ACTION ProductValuation~AddStocks RESULT result.
    METHODS validateStocks FOR VALIDATE ON SAVE
      IMPORTING keys FOR ProductValuation~validateStocks.

ENDCLASS.

CLASS lhc_productvaluation IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD AddStocks.

    READ ENTITIES OF zsac_r_product IN LOCAL MODE
        ENTITY ProductValuation
           ALL FIELDS WITH
           CORRESPONDING #( keys )
         RESULT DATA(lt_existing_products).

    DATA(ls_existing_product) = lt_existing_products[ 1 ].

* Adding 100 to existing stock quantity
    MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
           ENTITY ProductValuation
              UPDATE FIELDS ( TotalQuantity )
                 WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                                 TotalQuantity = ls_existing_product-TotalQuantity + 100 ) ).

    " Read changed data for action result
    READ ENTITIES OF zsac_r_product IN LOCAL MODE
      ENTITY ProductValuation
         ALL FIELDS WITH
         CORRESPONDING #( keys )
       RESULT DATA(lt_product_valuation).

    result = VALUE #( FOR ls_prod_val IN lt_product_valuation ( %tky      = ls_prod_val-%tky
                                                                %param    = ls_prod_val ) ).

  ENDMETHOD.

  METHOD validateStocks.

* Validate that if stock is entered, price cannot be empty
    READ ENTITIES OF zsac_r_product IN LOCAL MODE
          ENTITY ProductValuation
          FIELDS ( TotalQuantity StandardPrice ) WITH CORRESPONDING #( keys )
          RESULT DATA(lt_product_valuation).

    LOOP AT lt_product_valuation INTO DATA(ls_prod_val).
      IF ls_prod_val-TotalQuantity IS NOT INITIAL AND ls_prod_val-StandardPrice IS INITIAL.
        APPEND VALUE #( %tky = ls_prod_val-%tky ) TO failed-productvaluation.
        APPEND VALUE #( %tky = ls_prod_val-%tky
                        %element-StandardPrice = if_abap_behv=>mk-on
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = 'Price cannot be empty if stock is entered' )
                       ) TO reported-productvaluation.
      ENDIF.
    ENDLOOP.

* Validate that currency must not be empty if stock details are entered
    READ ENTITIES OF zsac_r_product IN LOCAL MODE
          ENTITY ProductValuation
          BY \_Product
          FIELDS ( CurrencyCode ) WITH CORRESPONDING #( keys )
          RESULT DATA(lt_product).

    LOOP AT lt_product INTO DATA(ls_product).
      IF lt_product_valuation IS NOT INITIAL AND ls_product-CurrencyCode IS INITIAL.
        APPEND VALUE #( %tky = ls_product-%tky ) TO failed-product.
        APPEND VALUE #( %tky = ls_product-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = 'Currency code cannot be empty' )
                       ) TO reported-product.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Product RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Product RESULT result.
    METHODS ResetMaterial FOR MODIFY
      IMPORTING keys FOR ACTION Product~ResetMaterial RESULT result.
    METHODS CreateProduct FOR MODIFY
      IMPORTING keys FOR ACTION Product~CreateProduct.
    METHODS setSomeValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Product~setSomeValues.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Product.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Product RESULT result.
    METHODS precheck_createproduct FOR PRECHECK
      IMPORTING keys FOR ACTION product~createproduct.

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.

    DATA: update_requested TYPE abap_bool.

    READ ENTITIES OF zsac_r_product IN LOCAL MODE
      ENTITY Product
      FIELDS ( IndustrySector ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_products)
      FAILED failed.
    CHECK lt_products IS NOT INITIAL.
    update_requested = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on THEN
                                    abap_true ELSE abap_false ).

* Update is granted only if Industry Sector is not 'P'
    LOOP AT lt_products ASSIGNING FIELD-SYMBOL(<lfs_product>).
      IF update_requested = abap_true.
        IF <lfs_product>-IndustrySector = 'P'.
          APPEND VALUE #( %tky = keys[ 1 ]-%tky
                          %msg = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text = 'No Authorization to update product!!!'
                                 )
                        ) TO reported-product.
        ENDIF.
      ENDIF.
    ENDLOOP.

    result = VALUE #( FOR ls_product IN lt_products
                        ( %tky = ls_product-%tky
                          %update = COND #( WHEN ls_product-IndustrySector = 'P'
                                          THEN if_abap_behv=>auth-unauthorized
                                          ELSE if_abap_behv=>auth-allowed )
*                          %action-Edit = COND #( WHEN ls_product-IndustrySector = 'P'
*                                                  THEN if_abap_behv=>auth-unauthorized
*                                                  ELSE if_abap_behv=>auth-allowed
*                                               )
                        )
                    ).

  ENDMETHOD.

  METHOD get_global_authorizations.

    DATA(create_requested) = COND #( WHEN requested_authorizations-%create = if_abap_behv=>mk-on THEN
                                    abap_true ELSE abap_false ).

* Disable create action after 08:00 AM system time
    IF create_requested = abap_true.
      IF cl_abap_context_info=>get_system_time( ) > '080000'.
        result-%create = if_abap_behv=>auth-unauthorized.
      ENDIF.

*     Custom message
      APPEND VALUE #( %msg = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text = 'Create not allowed after 8AM.'
                           )
                   ) TO reported-product.

    ENDIF.

  ENDMETHOD.

  METHOD ResetMaterial.

* Reset Industry Sector, Unit of Measure and Currency Code to initial values
    MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
           ENTITY Product
              UPDATE FIELDS ( IndustrySector UnitOfMeasure CurrencyCode )
                 WITH VALUE #( FOR key IN keys ( %tky      = key-%tky
                                                 IndustrySector = ''
                                                 UnitOfMeasure = ''
                                                 CurrencyCode = '' ) ).

* Read changed data for action result
    READ ENTITIES OF zsac_r_product IN LOCAL MODE
      ENTITY Product
         ALL FIELDS WITH
         CORRESPONDING #( keys )
       RESULT DATA(lt_products).

* Pass the result back to the action
    result = VALUE #( FOR ls_product IN lt_products ( %tky      = ls_product-%tky
                                                      %param    = ls_product ) ).

  ENDMETHOD.

  METHOD CreateProduct.

    DATA: lv_industry TYPE mbrsh.

    DATA(ls_key) = keys[ 1 ].

    lv_industry = ls_key-%param-Industry.

    SELECT SINGLE FROM zsac_t_prod_ind FIELDS unit_of_measure, currency_code
    WHERE industry_sector = @lv_industry INTO @DATA(ls_industry_data).

* If industry sector is valid, create the product with corresponding unit of measure and currency code
    IF sy-subrc IS INITIAL.
      MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
        ENTITY Product
        CREATE FIELDS ( ProductId IndustrySector UnitOfMeasure CurrencyCode )
        WITH VALUE #(
          FOR key IN keys (
            %cid            = key-%cid
            ProductId       = key-%param-ProductId
            IndustrySector  = key-%param-Industry
            UnitOfMeasure   = ls_industry_data-unit_of_measure
            CurrencyCode    = ls_industry_data-currency_code
          )
        )
        MAPPED   mapped
        FAILED   failed
        REPORTED reported.
    ELSE.
      APPEND VALUE #(  %cid = ls_key-%cid ) TO failed-product.
      APPEND VALUE #(  %cid = ls_key-%cid
                       %msg      = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                         text     = 'Failed to create. Please enter correct Industry' )
                    ) TO reported-product.

    ENDIF.

  ENDMETHOD.

  METHOD setSomeValues.

    READ ENTITIES OF zsac_r_product IN LOCAL MODE
       ENTITY Product
         FIELDS ( IndustrySector )
            WITH CORRESPONDING #( keys )
          RESULT DATA(lt_products).

* Determine Unit of Measure and Currency Code based on Industry Sector
    SELECT FROM zsac_t_prod_ind
     FIELDS industry_sector, unit_of_measure, currency_code
     FOR ALL ENTRIES IN @lt_products
     WHERE industry_sector = @lt_products-IndustrySector
     INTO TABLE @DATA(lt_industry_data).

    MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
      ENTITY Product
        UPDATE FIELDS ( UnitOfMeasure CurrencyCode )
        WITH VALUE #( FOR ls_product IN lt_products  (
                           %tky         = ls_product-%tky
                           UnitOfMeasure  = VALUE #( lt_industry_data[ industry_sector = ls_product-IndustrySector ]-unit_of_measure OPTIONAL )
                           CurrencyCode  = VALUE #( lt_industry_data[ industry_sector = ls_product-IndustrySector ]-currency_code OPTIONAL ) ) ).

  ENDMETHOD.

  METHOD precheck_create.

    DATA(ls_entity) = entities[ 1 ].

* Validate if entered Product ID already exists
    SELECT SINGLE FROM zsac_t_product
      FIELDS product_id
      WHERE product_id = @ls_entity-ProductId
      INTO @DATA(lv_existing_product_id).

    IF sy-subrc IS INITIAL.
      APPEND VALUE #(  %key = ls_entity-%key ) TO failed-product.
      APPEND VALUE #(  %key = ls_entity-%key
                       %msg      = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                         text     = | Product ID | && ls_entity-ProductId && | already exists.| )
                       %element-ProductId = if_abap_behv=>mk-on
                    ) TO reported-product.
    ENDIF.

* Validate if Industry Sector is entered, unit of measure and currency code cannot be empty
    IF ls_entity-IndustrySector IS NOT INITIAL
    AND ( ls_entity-UnitOfMeasure IS INITIAL OR ls_entity-CurrencyCode IS INITIAL ).
      APPEND VALUE #(  %key = ls_entity-%key ) TO failed-product.
      APPEND VALUE #(  %key = ls_entity-%key
                       %msg      = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                         text     = 'Unit of measure and currency code cannot be empty.' )
                       %element-IndustrySector = if_abap_behv=>mk-on
                    ) TO reported-product.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zsac_r_product IN LOCAL MODE
         ENTITY Product
           FIELDS ( MaterialType IndustrySector MaterialGroup )
              WITH CORRESPONDING #( keys )
            RESULT DATA(lt_products).

* If Material Type 'FERT' and Industry Sector is entered, Unit of Measure and Currency Code are read-only
* And If Material Group is entered, updating the product is disabled
    result =
        VALUE #( FOR ls_product IN lt_products
          ( %key = ls_product-%key
            %features-%field-UnitOfMeasure = COND #( WHEN ls_product-MaterialType = 'HAWA' AND ls_product-IndustrySector IS NOT INITIAL
                                                          THEN if_abap_behv=>fc-f-read_only
                                                          ELSE if_abap_behv=>fc-f-unrestricted )
            %features-%field-CurrencyCode = COND #( WHEN ls_product-MaterialType = 'FERT' AND ls_product-IndustrySector IS NOT INITIAL
                                                          THEN if_abap_behv=>fc-f-read_only
                                                          ELSE if_abap_behv=>fc-f-unrestricted )
*            %features-%update = COND #( WHEN ls_product-MaterialGroup IS NOT INITIAL
*                                          THEN if_abap_behv=>fc-o-disabled
*                                          ELSE if_abap_behv=>fc-o-enabled )
           ) ).

  ENDMETHOD.

  METHOD precheck_CreateProduct.

    DATA(lv_product_id) = keys[ 1 ]-%param-ProductID.

    SELECT SINGLE * FROM zsac_r_product WHERE productid = @lv_product_id INTO @DATA(ls_product).

* Validate if entered Product ID already exists
    SELECT SINGLE FROM zsac_t_product
      FIELDS product_id
      WHERE product_id = @lv_product_id
      INTO @DATA(lv_existing_product_id).

    IF sy-subrc IS INITIAL.
      APPEND VALUE #(  %cid = keys[ 1 ]-%cid ) TO failed-product.
      APPEND VALUE #(  %cid = keys[ 1 ]-%cid
                       %msg      = new_message_with_text(
                         severity = if_abap_behv_message=>severity-error
                         text     = | Product ID | && lv_product_id && | already exists.| )
                       %element-ProductId = if_abap_behv=>mk-on
                    ) TO reported-product.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
