CLASS lhc_productvaluation DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ProductValuation RESULT result.

    METHODS AddStocks FOR MODIFY
      IMPORTING keys FOR ACTION ProductValuation~AddStocks RESULT result.

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

ENDCLASS.

CLASS lhc_Product IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD ResetMaterial.

    " Modify in local mode: BO-related updates that are not relevant for authorization checks
    MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
           ENTITY Product
              UPDATE FIELDS ( IndustrySector UnitOfMeasure CurrencyCode )
                 WITH VALUE #( FOR key IN keys ( %tky      = key-%tky
                                                 IndustrySector = ''
                                                 UnitOfMeasure = ''
                                                 CurrencyCode = '' ) ).

    " Read changed data for action result
    READ ENTITIES OF zsac_r_product IN LOCAL MODE
      ENTITY Product
         ALL FIELDS WITH
         CORRESPONDING #( keys )
       RESULT DATA(lt_products).

    result = VALUE #( FOR ls_product IN lt_products ( %tky      = ls_product-%tky
                                                      %param    = ls_product ) ).

  ENDMETHOD.

  METHOD CreateProduct.

    DATA: lv_industry TYPE mbrsh.

    DATA(ls_key) = keys[ 1 ].

    lv_industry = ls_key-%param-Industry.

    SELECT SINGLE FROM zsac_t_prod_ind FIELDS unit_of_measure, currency_code
    WHERE industry_sector = @lv_industry INTO @DATA(ls_industry_data).

    IF sy-subrc IS INITIAL.
      MODIFY ENTITIES OF zsac_r_product IN LOCAL MODE
        ENTITY Product
        CREATE FIELDS ( ProductId IndustrySector UnitOfMeasure CurrencyCode )
        WITH VALUE #(
          FOR key IN keys (
            %cid       = key-%cid
            ProductId         = key-%param-ProductId
            IndustrySector      = key-%param-Industry
            UnitOfMeasure      = ls_industry_data-unit_of_measure
            CurrencyCode        = ls_industry_data-currency_code
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

ENDCLASS.
