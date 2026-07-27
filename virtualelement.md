# RAP Virtual Elements: Calculated Field via SADL Exit

This document covers adding a virtual element `TotalValuation` on the product projection view `zsac_c_product`, calculated by summing `StandardPrice` across all associated `_ProductValuation` child entries.

---

## 1. CDS Changes

### Virtual element on the projection

Add the virtual field to `zsac_c_product`. The `@ObjectModel.virtualElementCalculatedBy` annotation points to the exit class that supplies the value at runtime; the field itself carries no mapping to any DB column.

```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Projection View - Product'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zsac_c_product
  provider contract transactional_query
  as projection on ZSAC_R_Product
{
  key ProductUuid,
      ProductId,
      MaterialType,
      IndustrySector,
      MaterialGroup,
      UnitOfMeasure,
      CurrencyCode,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZSAC_CL_VALUATION_VE_EXIT'
      virtual TotalValuation : abap.curr(15,2),

      _ProductText : redirected to composition child zsac_c_product_text,
      _ProductValuation : redirected to composition child zsac_c_product_valuation
}
```

`zsac_c_product_valuation` itself stays unchanged, no CDS annotation is required on the child:

```cds
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View - Product Valuation'
@Metadata.allowExtensions: true
define view entity zsac_c_product_valuation as projection on zsac_i_product_valuation
{
    key ProdValUuid,
    ProductUuid,
    ValuationType,
    TotalQuantity,
    StandardPrice,
    UnitOfMeasure,
    CurrencyCode,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,

    /* Associations */
    _Product: redirected to parent zsac_c_product
}
```

---

## 2. Exit Class

The calculation runs in an `if_sadl_exit_calc_element_read` implementation. Unlike a scenario where the sum comes from a *child* entity read via `\_Item` off the same root, here the total comes from the sibling composition `_ProductValuation`, so the read is `READ ENTITIES OF zsac_c_product ... BY \_ProductValuation`, keyed on `ProductUuid` rather than `BillId`.

Sort exit support is intentionally left out. Since `TotalValuation` is a runtime aggregate with no backing DB column, it cannot be pushed down to the database for sorting, so `if_sadl_exit_sort_transform` is omitted from this class.

```abap
CLASS zsac_cl_valuation_ve_exit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zsac_cl_valuation_ve_exit IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~calculate.

    " Loop over all requested virtual elements. In this app there is only
    " one (TotalValuation), but the framework always passes a table so a
    " single exit class can serve multiple virtual fields if needed.
    LOOP AT it_requested_calc_elements INTO DATA(lv_virtual_field_name).

      " Loop over each row returned by the main query (one row per Product).
      LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<ls_calculated_row>).

        DATA(lv_index) = sy-tabix.

        " Assign the virtual field dynamically, since the field name is
        " only known at runtime (it comes from it_requested_calc_elements).
        ASSIGN COMPONENT lv_virtual_field_name
          OF STRUCTURE <ls_calculated_row>
          TO FIELD-SYMBOL(<lv_total_valuation>).

        " Read the corresponding original product row for this index, to
        " get the real key (ProductUuid) the virtual field belongs to.
        DATA(ls_product_data) =
          CORRESPONDING zsac_r_product( it_original_data[ lv_index ] ).

        " Read associated valuation entries for the current Product, via
        " the composition child _ProductValuation (sibling read, not a
        " parent-to-child \_Item style read as in the billing doc case).
        " EML always targets the root behavior definition entity
        " (ZSAC_R_Product), not the projection view (zsac_c_product) that
        " carries the virtual element annotation.
        READ ENTITIES OF zsac_r_product
          ENTITY product
          BY \_ProductValuation
          ALL FIELDS
          WITH VALUE #( ( ProductUuid = ls_product_data-ProductUuid ) )
          RESULT DATA(lt_valuation_data).

        " Initialize total valuation before summing.
        CLEAR <lv_total_valuation>.

        " Sum all StandardPrice values across the product's valuation
        " entries to arrive at the total valuation for this row.
        LOOP AT lt_valuation_data INTO DATA(ls_valuation_row).
          <lv_total_valuation> =
            <lv_total_valuation> + ls_valuation_row-StandardPrice.
        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.

ENDCLASS.
```

---

## Quick Reference

| Aspect | Detail |
|---|---|
| Virtual field | `TotalValuation` on `zsac_c_product` |
| Source data | `StandardPrice` summed across `_ProductValuation` entries |
| Annotation | `@ObjectModel.virtualElementCalculatedBy: 'ABAP:ZSAC_CL_VALUATION_VE_EXIT'` |
| Read direction | Sibling composition child (`\_ProductValuation`), keyed on `ProductUuid` |
| EML target | `ZSAC_R_Product` (behavior root entity, alias `Product`), not the `zsac_c_product` projection |
| Interfaces required | `if_sadl_exit`, `if_sadl_exit_calc_element_read` |
| Sort support | Not implemented, virtual elements without a DB column can't be sorted at the database level |
