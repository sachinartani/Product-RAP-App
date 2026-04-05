CLASS zsac_cl_load_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZSAC_CL_LOAD_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


    DATA: lt_industries TYPE TABLE OF zsac_t_prod_ind.

    " Preparing data based on your image and logical UoM/Currency associations
    lt_industries = VALUE #(
      ( industry_sector = '1' unit_of_measure = 'KG'  currency_code = 'EUR' ) " Retail
      ( industry_sector = '2' unit_of_measure = 'TO'  currency_code = 'USD' ) " Commodity Management
      ( industry_sector = 'A' unit_of_measure = 'H'   currency_code = 'EUR' ) " Plant Engineering
      ( industry_sector = 'B' unit_of_measure = 'L'   currency_code = 'GBP' ) " Beverage
      ( industry_sector = 'C' unit_of_measure = 'KJ'  currency_code = 'USD' ) " Chemical Industry
      ( industry_sector = 'H' unit_of_measure = 'ST'  currency_code = 'CHF' ) " Healthcare
      ( industry_sector = 'M' unit_of_measure = 'TO'  currency_code = 'EUR' ) " Mechanical
      ( industry_sector = 'P' unit_of_measure = 'ST'  currency_code = 'USD' ) " Pharmaceuticals
      ( industry_sector = 'T' unit_of_measure = 'MIN' currency_code = 'EUR' ) " Telecommunication
    ).

    " Delete existing records to avoid duplicate key errors during re-runs
    DELETE FROM zsac_t_prod_ind.

    " Insert new data
    INSERT zsac_t_prod_ind FROM TABLE @lt_industries.

    out->write( |{ sy-dbcnt } Industry Sectors inserted successfully.| ).


DATA: lt_product TYPE STANDARD TABLE OF zsac_t_product,
          lt_text    TYPE STANDARD TABLE OF zsac_t_prod_txt,
          lt_val     TYPE STANDARD TABLE OF zsac_t_prod_val.


    DATA: lv_ts TYPE timestampl,
          lv_uuid TYPE sysuuid_x16.


get time STAMP FIELD lv_ts.

    "-----------------------------
    " Create Products
    "-----------------------------
    DO 5 TIMES.

      TRY.
          lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.

      APPEND VALUE #(
        client            = sy-mandt
        product_uuid      = lv_uuid
        product_id        = |MAT{ sy-index }|
        material_type     = 'FERT'
        industry_sector   = 'M'
        material_group    = 'GRP1'
        unit_of_measure   = 'EA'
        currency_code     = 'INR'
        created_by        = sy-uname
        created_at        = lv_ts
        last_changed_by   = sy-uname
        last_changed_at   = lv_ts
        local_last_changed_at = lv_ts
      ) TO lt_product.

      "-----------------------------
      " Product Texts (2 per product)
      "-----------------------------
      TRY.
          APPEND VALUE #(
            client       = sy-mandt
            prod_txt_uuid = cl_system_uuid=>create_uuid_x16_static( )
            product_uuid = lv_uuid
            language     = 'E'
            description  = |Product { sy-index } - English|
            created_by   = sy-uname
            created_at   = lv_ts
            last_changed_by = sy-uname
            last_changed_at = lv_ts
            local_last_changed_at = lv_ts
          ) TO lt_text.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.

      TRY.
          APPEND VALUE #(
            client       = sy-mandt
            prod_txt_uuid = cl_system_uuid=>create_uuid_x16_static( )
            product_uuid = lv_uuid
            language     = 'D'
            description  = |Product { sy-index } - German|
            created_by   = sy-uname
            created_at   = lv_ts
            last_changed_by = sy-uname
            last_changed_at = lv_ts
            local_last_changed_at = lv_ts
          ) TO lt_text.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.

      "-----------------------------
      " Product Valuations (2 per product)
      "-----------------------------
      TRY.
          APPEND VALUE #(
            client        = sy-mandt
            prod_val_uuid = cl_system_uuid=>create_uuid_x16_static( )
            product_uuid  = lv_uuid
            valuation_type = 'STD'
            total_quantity = 100 * sy-index
            standard_price = 500 * sy-index
            created_by     = sy-uname
            created_at     = lv_ts
            last_changed_by = sy-uname
            last_changed_at = lv_ts
            local_last_changed_at = lv_ts
          ) TO lt_val.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.

      TRY.
          APPEND VALUE #(
            client        = sy-mandt
            prod_val_uuid = cl_system_uuid=>create_uuid_x16_static( )
            product_uuid  = lv_uuid
            valuation_type = 'MOV'
            total_quantity = 50 * sy-index
            standard_price = 450 * sy-index
            created_by     = sy-uname
            created_at     = lv_ts
            last_changed_by = sy-uname
            last_changed_at = lv_ts
            local_last_changed_at = lv_ts
          ) TO lt_val.
        CATCH cx_uuid_error.
          "handle exception
      ENDTRY.

    ENDDO.

    "-----------------------------
    " Insert into DB
    "-----------------------------
    INSERT zsac_t_product FROM TABLE @lt_product.
    INSERT zsac_t_prod_txt FROM TABLE @lt_text.
    INSERT zsac_t_prod_val FROM TABLE @lt_val.

    out->write( |Inserted { lines( lt_product ) } products with texts and valuations| ).

* Working example of Service Consumption using OData V4 Client Proxy
*    TYPES: BEGIN OF tys_alphabetical_list_of_produ,
*
*             product_id        TYPE int4,        " Edm.Int32, not nullable
*             product_name      TYPE string,      " Edm.String
*             supplier_id       TYPE int4,        " Edm.Int32
*             category_id       TYPE int4,        " Edm.Int32
*             quantity_per_unit TYPE string,      " Edm.String
*             unit_price        TYPE decfloat34,  " Edm.Decimal
*             units_in_stock    TYPE int2,        " Edm.Int16
*             units_on_order    TYPE int2,        " Edm.Int16
*             reorder_level     TYPE int2,        " Edm.Int16
*             discontinued      TYPE abap_bool,   " Edm.Boolean, not nullable
*
*           END OF tys_alphabetical_list_of_produ.
*
*    DATA:
*      ls_entity_key    TYPE tys_alphabetical_list_of_produ,
*      ls_business_data TYPE tys_alphabetical_list_of_produ,
*      lo_http_client   TYPE REF TO if_web_http_client,
*      lo_resource      TYPE REF TO /iwbep/if_cp_resource_entity,
*      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
*      lo_request       TYPE REF TO /iwbep/if_cp_request_read,
*      lo_response      TYPE REF TO /iwbep/if_cp_response_read.
*
*
*
*    TRY.
*        " Create http client
**DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
**                                             comm_scenario  = '<Comm Scenario>'
**                                             comm_system_id = '<Comm System Id>'
**                                             service_id     = '<Service Id>' ).
**lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
*        DATA(lo_destination) = cl_http_destination_provider=>create_by_url( 'https://services.odata.org' ).
*        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
*        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v4_remote_proxy(
*          EXPORTING
*             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
*                                                 proxy_model_id      = 'ZTEST_NORTHWIND'
*                                                 proxy_model_version = '0001' )
*            io_http_client             = lo_http_client
*            iv_relative_service_root   = '/v4/northwind/northwind.svc' ).
*
*        ASSERT lo_http_client IS BOUND.
*
*        " Set entity key
*        ls_entity_key = VALUE #(
*                  product_id     = 1 ).
*
*        " Navigate to the resource
*        lo_resource = lo_client_proxy->create_resource_for_entity_set( 'PRODUCTS' )->navigate_with_key( ls_entity_key ).
*
*        " Execute the request and retrieve the business data
*        lo_response = lo_resource->create_request_for_read( )->execute( ).
*        lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).
*
*        out->write( ls_business_data ).
*
*      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
*        " Handle remote Exception
*        " It contains details about the problems of your http(s) connection
*
*      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
*        " Handle Exception
*
*      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
*        " Handle Exception
*        RAISE SHORTDUMP lx_web_http_client_error.
*
*
*    ENDTRY.

  ENDMETHOD.
ENDCLASS.
