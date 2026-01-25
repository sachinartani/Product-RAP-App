@AccessControl.authorizationCheck: #NOT_REQUIRED
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
      LocalLastChangedAt
}
