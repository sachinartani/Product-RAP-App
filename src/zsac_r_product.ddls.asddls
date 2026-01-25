@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view - Product'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZSAC_R_Product
  as select from zsac_t_product
{
  key product_uuid          as ProductUuid,
      product_id            as ProductId,
      material_type         as MaterialType,
      industry_sector       as IndustrySector,
      material_group        as MaterialGroup,
      unit_of_measure       as UnitOfMeasure,
      currency_code         as CurrencyCode,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
