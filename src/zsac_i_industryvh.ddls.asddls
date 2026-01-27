@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Product Industry'
@Metadata.ignorePropagatedAnnotations: true
define view entity zsac_i_industryvh
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZSAC_DO_INDUSTRY')
{
  @ObjectModel.text.element: ['Description']
  key value_low as Industry,
      @Semantics.text: true
      text as Description
}
where language = $session.system_language
