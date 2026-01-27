@EndUserText.label: 'Abstract Entity - Product'
define abstract entity zsac_a_product
{
    @EndUserText.label: 'Product ID'
    @Consumption.filter.mandatory: true
    ProductID: matnr;
    @EndUserText.label: 'Industry'
    @Consumption.filter.mandatory: true
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZSAC_I_INDUSTRYVH', element: 'Industry' } }]
    Industry : mbrsh;
}
