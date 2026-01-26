@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View - Product Text'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zsac_c_product_text as projection on zsac_i_product_text
{
    key ProdTxtUuid,
    ProductUuid,
    Language,
    Description,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    
    /* Associations */
    _Product : redirected to parent zsac_c_product
}
