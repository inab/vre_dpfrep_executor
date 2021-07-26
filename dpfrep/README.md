# DpFrEP: Drug Prediction from Expression Profile

DpFrEP proposed a method that estimates the anticancer effect of a set of drugs on bulk expression profiles provided in
input. For each drug and for each profile, the enrichment extent of top\/bottom expressed genes in marker genes of drug
sensitivity\/resistance, previously precompiled, and vice versa, is quantified using Gene Set Enrichment Analysis (GSEA)
. Then, for each GSEA strategy, the probability of obtaining smaller\/greater enrichment scores (ESs) than the observed
ones, from randomized expression profiles, is determined independently. Last, the geometric mean of individual
probabilities, G, is computed to assess the overall drug efficacy. The smaller the G-value, the higher the drug
efficacy, thereby the likelihood that the profile is sensitive to the drug. Finally, a drug ranked list is generated for
each profile provided in input by sorting drug G-values in ascending order.