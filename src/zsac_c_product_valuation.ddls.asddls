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
