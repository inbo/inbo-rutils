#' @title Query header information from INBOVEG
#'
#' @description This function queries the INBOVEG database for header
#' information (metadata for a vegetation-relevé) for one survey by the name
#' of the survey and the recorder type. See the examples for how to get
#' information for all surveys.
#'
#' @param survey_name A character vector giving the name of the survey for which
#' you want to extract header information. If missing, all surveys are returned.
#' @param rec_type A character vector giving the name of record type for which
#' you want to extract header information e.g. 'Classic', 'Classic-emmer',
#' 'Classic-ketting', 'BioHab', 'ABS'. If missing, all recording types are returned.
#' @param connection dbconnection with the database 'Cydonia'
#' on the inbo-sql07-prd server
#' @param collect If FALSE (the default), a remote tbl object is returned.
#' This is like a reference to the result of the query but the full result of
#' the query is not brought into memory. If TRUE the full result of the query is
#' collected (fetched) from the database and brought into memory of the working
#' environment.
#'
#' @return A remote tbl object (collect = FALSE) or a tibble dataframe (collect
#' = TRUE) with variables RecordingGivid, Name, UserReference, LocationCode,
#' Latitude, Longitude, Area (in m2), Length (in cm), Width (in cm), SurveyId, RecTypeID.
#'
#' @importFrom glue glue_sql
#' @importFrom DBI dbGetQuery
#' @importFrom assertthat assert_that
#' @importFrom dplyr collect tbl sql
#'
#' @export
#' @family inboveg
#' @examples
#' \dontrun{
#' con <- connect_inbo_dbase("D0010_00_Cydonia")
#' 
#' # get header information from a specific survey and a specific recording type
#' and collect the data
#' header_info <- inboveg_header(con, survey_name = "OudeLanden_1979",
#' rec_type = "Classic", collect = TRUE)
#' 
#' # get header information of all surveys,  don't collect the data
#' all_header_info <- inboveg_header(con)
#' 
#' # Close the connection when done
#' dbDisconnect(con)
#' rm(con)
#' }


inboveg_header <- function(connection,
                           survey_name,
                           rec_type,
                           collect = FALSE) {

  assert_that(inherits(connection, what = "Microsoft SQL Server"),
              msg = "Not a connection object to database.")

  if (missing(survey_name)) {
    survey_name <- "%"
  } else {
    assert_that(is.character(survey_name))
  }

  if (missing(rec_type)) {
    rec_type <- "%"
  } else {
    assert_that(is.character(rec_type))
  }

  sql_statement <- glue_sql(
    "SELECT
      ivR.[RecordingGivid]
      , ivS.Name
      , ivR.UserReference
      , ivR.LocationCode
      , ivR.Latitude
      , ivR.Longitude
      , COALESCE(ivR.Length * ivR.Width / 10000, try_convert(decimal, ivR.Area)) AS Area
      , ivR.Length
      , ivR.Width
      , ivR.SurveyId
      , ivR.RecTypeID
      FROM [dbo].[ivRecording] ivR
      INNER JOIN [dbo].[ivSurvey] ivS on ivS.Id = ivR.SurveyId
      INNER JOIN [dbo].[ivRecTypeD] ivRec on ivRec.ID = ivR.RecTypeID
      where ivR.NeedsWork = 0
      AND ivS.Name LIKE {survey_name}
      AND ivREc.Name LIKE {rec_type}",
    survey_name = survey_name,
    rec_type = rec_type,
    .con = connection)

query_result <- tbl(connection, sql(sql_statement))

if (!isTRUE(collect)) {
  return(query_result)
} else {
  query_result <- collect(query_result)
  return(query_result)
 }
}