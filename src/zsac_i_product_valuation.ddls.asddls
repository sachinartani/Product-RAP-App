@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view -  Product Valuation'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsac_i_product_valuation
  as select from zsac_t_prod_val
  association to parent ZSAC_R_Product as _Product on $projection.ProductUuid = _Product.ProductUuid
{
  key prod_val_uuid          as ProdValUuid,
      product_uuid           as ProductUuid,
      valuation_type         as ValuationType,

      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
      total_quantity         as TotalQuantity,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      standard_price         as StandardPrice,

      _Product.UnitOfMeasure as UnitOfMeasure,
      _Product.CurrencyCode  as CurrencyCode,

      @Semantics.user.createdBy: true
      created_by             as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at             as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by        as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at        as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at  as LocalLastChangedAt,

      _Product
}
