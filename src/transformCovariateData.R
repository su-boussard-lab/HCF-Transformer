

generateInputatMatrix <- function (covariateData) 
{
  inputMatrix <- as.data.frame(covariateData$covariates)
  
  rowIds <- unique(inputMatrix$rowId)
  covariateIds <- unique(inputMatrix$covariateId)
  
  inputMatrix$rowIndex <- match(inputMatrix$rowId, rowIds) 
  inputMatrix$colIndex <- match(inputMatrix$covariateId, covariateIds) 
  
  spMatrix <- Matrix::sparseMatrix(i = inputMatrix$rowIndex, j = inputMatrix$colIndex, x = inputMatrix$covariateValue,  
                           dims = c(length(rowIds), length(covariateIds)),  
                           dimnames = list(rowIds, covariateIds))
  
  spMatrix <- as.data.frame(as(spMatrix, "matrix"))
  return(spMatrix)
}





