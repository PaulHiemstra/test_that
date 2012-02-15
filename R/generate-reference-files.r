.get_reference = function(pattern, rdapath = "reffiles") {
  # Load the reference file
  ref.fname = sprintf("%s/%s.rda", rdapath, pattern)
  tmp.env = new.env()
  load(ref.fname, envir = tmp.env)
  ref.obj = unlist(.obj_from_envir(tmp.env), recursive = FALSE)
  names(ref.obj) = sub("obj.", "", names(ref.obj))  
  return(ref.obj)
}

.generate_ref_file = function(expr, savePrefix, rdapath = "reffiles") {  
  # Generate a reference file in the requested location
  # given the code in expr
  if(!file.exists(rdapath)) dir.create(rdapath)  
  obj = .expr_to_list(expr)
  save(obj, file = sprintf("%s/%s.rda", rdapath, savePrefix))
}

.check_expr = function(expr) {
  # Check if the expression has class 'character'
  if(!inherits(expr, "character")) {
    class_char = paste(class(expr), collapse = ", ")
    mesg = sprintf("Expression is not of class 'character' but of class %s", class(expr))
    stop(mesg)
  }
}

.expr_to_list = function(expr) {
  # Evaluate the expression and return the resulting objects
  # in a list. Does this by executing the command in a new
  # environment and than loading the objects from that environment
  # into a list.
  .check_expr(expr)
  tmp.env = new.env()
  eval(parse(text = expr), envir = tmp.env)
  return(.obj_from_envir(tmp.env))
}

.obj_from_envir = function(env.name) {  
  # Extract an list of the objects present in 
  # the given environment
  lsobjs = ls(envir = env.name)
  objs = lapply(lsobjs, get, envir = env.name)
  names(objs) = lsobjs
  return(objs)
}

.reference_missing = function(savePrefix, rdapath = "reffiles") {  
  # Return wether the reference file is missing
  return(!file.exists(sprintf("%s/%s.rda", rdapath, savePrefix)))
}

## User functions
#' Test if the current result differs from a stored reference
#' 
#' This function executes the expression given to it by the user. It 
#' returns both the result of the expression and the reference read from
#' file to allow a test if they are equal.
#'
#' @param expr character vector with the expression used in the test, remember to escape any
#'             quotation marks in the character expression.                
#' @param savePrefix, prefix used in the file name that the reference is stored in
#' @param rdapath path to the reference files
#' @param verbose logical, if TRUE, report when a reference file is regenerated.
#' @value a list with two parts: \code{reference} containing the reference object 
#'        read from file, and \code{current} the freshly calculated current object.
#' @details If you want to use quotation marks in your expression, please escape the quotes. Alternatively
#'          mix ' and " quotes. If you want to use variables in your expression, remember to make them global using
#'          <<-. This is not an ideal situation, but because all code is ran in separate environments, and 
#'          evaluation is postponed to within the function \code{testthat:::.expr_to_list}, the globalization
#'          is needed.
#' @author Paul Hiemstra, \email{p.h.hiemstra@@gmail.com}
#' @seealso \code{\link{matches_ref_current}}, \code{\link{clear_reference_cache}}
#' @export
#' @examples
#' \dontrun{
#' test1 = test_reference_change("{a<-runif(1)
#'                                b<-runif(2)}", savePrefix = "random")
#' test2 = test_reference_change("{a<-1
#'                                b<-3}", savePrefix = "test")
#' test_that("Reference stuff works", {
#'   expect_that(matches_ref_current(test1), is_false())
#'   expect_that(matches_ref_current(test2), is_true())
#' })
#' }
test_reference_change = function(expr, savePrefix, rdapath = "reffiles", verbose = FALSE) {                                                                                       
  if(.reference_missing(savePrefix, rdapath)) {
    if(verbose) cat("r")    
    .generate_ref_file(expr, savePrefix, rdapath)
  }
  reference = .get_reference(savePrefix, rdapath)
  current = .expr_to_list(expr)
  return(list(reference = reference, current = current))
}

#' Deletes the stored reference files
#' 
#' This function removes the reference files that have been stored previously.
#'
#' @param savePrefix either NULL (default) or a list of prefixes do be deleted. If the 
#'                   this parameter is NULL, all reference files are deleted.
#' @param rdapath path to the reference files
#' @author Paul Hiemstra, \email{p.h.hiemstra@@gmail.com}
#' @seealso \code{\link{test_reference_change}}, \code{\link{matches_ref_current}}

#' @export
#' @examples
#' \dontrun{
#'  test1 = test_reference_change("{a<-runif(1)
#'                                b<-runif(2)}", savePrefix = "random")
#'  test2 = test_reference_change("{a<-1
#'                                b<-3}", savePrefix = "test")
#'  test_that("Reference stuff works", {
#'   expect_that(matches_ref_current(test1), is_false())
#'   expect_that(matches_ref_current(test2), is_true())
#'  })
#' 
#'  clear_reference_cache()
#'  clear_reference_cache("random")
#' }
clear_reference_cache = function(savePrefix = NULL, rdapath = "reffiles") {
  if(is.null(savePrefix)) {
    file_list = list.files(rdapath, pattern = "rda", full.names = TRUE)
  } else {
    file_list = sprintf("%s/%s.rda", rdapath, savePrefix)
  }
  succes = sapply(file_list, file.remove)
  return(invisible(NULL))
}

#' Is the current object equal to the reference?
#' 
#' This function takes the output of the \code{\link{test_reference_change}}
#' and returns TRUE if the current object matches the reference, and FALSE otherwise
#'
#' @param reference_object object to perform the test on.
#' @value TRUE if the current object matches the reference object, and FALSE otherwise.
#' @author Paul Hiemstra, \email{p.h.hiemstra@@gmail.com}
#' @seealso \code{\link{test_reference_change}}, \code{\link{clear_reference_cache}}

#' @export
#' @examples
#' \dontrun{
#' test1 = test_reference_change("{a<-runif(1)
#'                                b<-runif(2)}", savePrefix = "random")
#' test2 = test_reference_change("{a<-1
#'                                b<-3}", savePrefix = "test")
#' test_that("Reference stuff works", {
#'   expect_that(matches_ref_current(test1), is_false())
#'   expect_that(matches_ref_current(test2), is_true())
#' })
#' }
matches_ref_current = function(reference_object) {
  return(isTRUE(all.equal(reference_object[["reference"]], reference_object[["current"]])))
}