library("RUnit")
library("tools")

source("AlgorithmiaClient.r")
source("DataDirectory.r")

test.invalidPath <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  checkException(client$dir(""))
  checkException(client$dir("/"))
  checkException(client$dir("data://"))
}

test.getName <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  checkEquals(client$dir("data://what")$getName(), "what")
  checkEquals(client$dir("data://a/b/c/")$getName(), "c")
  checkEquals(client$dir("/a/b/c/d")$getName(), "d")
}

test.existsNotThere <-function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/neverShouldExist")
  checkTrue(!dataDir$exists())
}

test.createAndDelete <-function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/RTest_createAndDelete")
  checkTrue(!dataDir$exists())

  checkEquals(dataDir$create(), dataDir)
  checkTrue(dataDir$exists())

  checkEquals(dataDir$delete(), dataDir)
  checkTrue(!dataDir$exists())
}

test.deleteForce <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/RTest_deleteForce")
  checkTrue(!dataDir$exists())

  checkEquals(dataDir$create(), dataDir)
  dataFile <- dataDir$file("file")
  dataFile$put("R delete force test")

  checkException(dataDir$delete())
  checkTrue(dataDir$exists())

  checkEquals(dataDir$delete(TRUE), dataDir)
  checkTrue(!dataDir$exists())
}

test.dir <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/")
  checkTrue(dataDir$exists())

  childDir <- dataDir$dir("RTest_dir")
  childDir$create()

  childDir$file("innerFile")$putJson(1)

  childDir$delete(TRUE)
  checkTrue(!childDir$exists())
}

test.dirListFilesSmall <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/RTest_dirListFilesSmall")
  checkTrue(!dataDir$exists())
  dataDir$create()

  dataDir$file("one")$put("one")
  dataDir$file("two")$put("two")

  filesFound <- c()
  fileIterator <- dataDir$files()

  while (fileIterator$hasNext()) {
    cur <- fileIterator$getNext()
    checkTrue(inherits(cur, "AlgorithmiaDataFile"))
    filesFound <- c(filesFound, cur$getName())
  }

  checkEquals(sort(filesFound), c("one", "two"))
  dataDir$delete(TRUE)
}

test.dirListDirectories <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/")

  dataDir1 <- dataDir$dir("RTest_dirListDirectories_1")
  dataDir2 <- dataDir$dir("RTest_dirListDirectories_2")

  if (!dataDir1$exists()) {
    dataDir1$create()
  }

  if (!dataDir2$exists()) {
    dataDir2$create()
  }

  seen1 <- FALSE
  seen2 <- FALSE

  folderIterator <- dataDir$dirs()
  while (folderIterator$hasNext()) {
    cur <- folderIterator$getNext()
    checkTrue(inherits(cur, "AlgorithmiaDataDirectory"))
    seen1 <- (seen1 || cur$getName() == "RTest_dirListDirectories_1")
    seen2 <- (seen2 || cur$getName() == "RTest_dirListDirectories_2")
  }
  checkTrue(seen1)
  checkTrue(seen2)

  dataDir1$delete()
  dataDir2$delete()
}

test.dirListFilesLarge <- function() {
  client <- getAlgorithmiaClient(Sys.getenv("ALGORITHMIA_API_KEY", unset=NA))
  dataDir <- client$dir("data://.my/RTest_dirListFilesLarge")

  NUM_FILES <- 1100
  if (!dataDir$exists()) {
    dataDir$create()

    fileCount <- 1
    while (fileCount <= NUM_FILES) {
      dataDir$file(paste0(fileCount, ".txt"))$putJson(fileCount)
      fileCount <- fileCount + 1
    }
  }

  seen <- vector(mode="logical", length=NUM_FILES)
  numSeen <- 0

  fileIterator <- dataDir$files()
  while (fileIterator$hasNext()) {
    cur <- fileIterator$getNext()
    index <- as.integer(gsub(".txt", "", cur$getName()))
    seen[index] <- TRUE
    numSeen <- numSeen + 1
  }

  andAll <- TRUE
  index <- 1
  while (index < NUM_FILES) {
    andAll <- (andAll && seen[index])
    index <- index + 1
  }

  checkEquals(numSeen, NUM_FILES)
  checkTrue(andAll)
}