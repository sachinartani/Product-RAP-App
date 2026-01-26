@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view -  Product Text'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsac_i_product_text
  as select from zsac_t_prod_txt
  association to parent ZSAC_R_Product as _Product
    on $projection.ProductUuid = _Product.ProductUuid
{
  key prod_txt_uuid         as ProdTxtUuid,
      product_uuid          as ProductUuid,
      language              as Language,
      description           as Description,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      
      _Product
}
