# Tests for Excel date cleaning function

library(janitor)
context("duplicate identification")

library(dplyr)
test_df <- data.frame(a = c(1, 3, 3, 3, 5), b = c("a", "c", "c", "e", "c"), stringsAsFactors = FALSE)

test_that("Correct combinations of duplicates are found", {
  expect_equal(get_dupes(test_df, a), data_frame(a = test_df[[1]][2:4], dupe_count = rep(3L, 3), b = test_df[[2]][2:4]))
  expect_equal(get_dupes(test_df, b), data_frame(b = test_df[[2]][c(2:3, 5)], dupe_count = rep(3L, 3), a = test_df[[1]][c(2:3, 5)]))
})

test_that("calling with no specified variable names uses all variable names", {
  expect_equal(get_dupes(test_df), get_dupes(test_df, a, b))
  expect_message(get_dupes(mtcars), "No variable names specified - using all columns.")
})

no_dupes <- data.frame(a = 1, stringsAsFactors = FALSE)

test_that("instances of no dupes throw correct messages, return empty df", {
  expect_message(no_dupes %>% get_dupes(a), "No duplicate combinations found of: a")
  expect_equal(suppressWarnings(no_dupes %>% get_dupes(a)), data_frame(a = double(0), dupe_count = integer(0)))
  expect_message(mtcars %>% select(-1) %>% get_dupes(), "No duplicate combinations found of: cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb")
  expect_message(mtcars %>% get_dupes(), "No duplicate combinations found of: mpg, cyl, disp, hp, drat, wt, qsec, vs, am, ... and 2 other variables")
})

test_that("incorrect variable names are handled", {
  expect_error(get_dupes(mtcars, x))
})

test_that("works on variables with irregular names", {
  badname_df <- mtcars %>% mutate(`bad name!` = mpg * 1000)
  expect_equal(
    badname_df %>% get_dupes(`bad name!`, cyl) %>% dim(),
    c(10, 13)
  ) # does it return the right-sized result?
  expect_is(badname_df %>% get_dupes(), "data.frame") # test for success, i.e., produces a data.frame (with 0 rows)
})

test_that("tidyselect specification matches exact specification", {
  expect_equal(mtcars %>% get_dupes(contains("cy"), mpg), mtcars %>% get_dupes(cyl, mpg))
  expect_equal(mtcars %>% get_dupes(mpg), mtcars %>% get_dupes(-c(cyl, disp, hp, drat, wt, qsec, vs, am ,gear, carb)))
  expect_equal(suppressMessages(mtcars %>% select(cyl, wt) %>% get_dupes()), mtcars %>% select(cyl, wt) %>% get_dupes(everything()))
})

test_that("grouped and ungrouped data is handled correctly", {
  expect_equal(suppressMessages(mtcars %>% group_by(carb, cyl) %>% get_dupes(mpg, carb)) %>% group_vars(), 
               mtcars %>% group_by(carb, cyl) %>% group_vars())
  expect_equal(suppressMessages(mtcars %>% group_by(carb, cyl) %>% get_dupes(mpg, carb) %>% ungroup()),
               mtcars %>% get_dupes(mpg, carb))
})