#' @title Plot the per base content as a heatmap
#'
#' @description Plot the Per Base content for a set of FASTQC files.
#'
#' @details
#' Per base sequence content (%A, %T, %G, %C), is shown as four overlaid
#' heatmap colours when plotting from multiple reports. The individual line
#' plots are able to be generated by setting `plotType = "line"`, and the
#' layout is determined by `facet_wrap` from ggplot2.
#'
#' Individual line plots are also generated when plotting from a single
#' `FastqcData` object.
#'
#' If setting `usePlotly = TRUE` for a large number of reports, the plot
#' can be slow to render.
#' An alternative may be to produce a plot of residuals for each base, produced
#' by taking the position-specific mean for each base.
#'
#' @param x Can be a `FastqcData`, `FastqcDataList` or file paths
#' @param labels An optional named vector of labels for the file names.
#' All file names must be present in the names of the vector.
#' File extensions are dropped by default.
#' @param usePlotly `logical`. Generate an interactive plot using plotly
#' @param plotType `character`. Type of plot to generate. Must be "line",
#' "heatmap" or "residuals"
#' @param pwfCols Object of class [PwfCols()] to give colours for
#' pass, warning, and fail
#' values in plot
#' @param cluster `logical` default `FALSE`. If set to `TRUE`,
#' fastqc data will be clustered using hierarchical clustering
#' @param dendrogram `logical` redundant if `cluster` is `FALSE`
#' if both `cluster` and `dendrogram` are specified as `TRUE`
#' then the dendrogram will be displayed.
#' @param ... Used to pass additional attributes to theme() and between methods
#' @param nc Specify the number of columns if plotting a FastqcDataList as line
#' plots. Passed to `ggplot2::facet_wrap`.
#'
#' @return A ggplot2 object or an interactive plotly object
#'
#' @examples
#'
#' # Get the files included with the package
#' packageDir <- system.file("extdata", package = "ngsReports")
#' fl <- list.files(packageDir, pattern = "fastqc.zip", full.names = TRUE)
#'
#' # Load the FASTQC data as a FastqcDataList object
#' fdl <- FastqcDataList(fl)
#'
#' # The default plot
#' plotSeqContent(fdl)
#'
#' @docType methods
#'
#' @importFrom grDevices rgb
#' @importFrom dplyr mutate_at vars group_by ungroup left_join
#' @importFrom scales percent
#' @importFrom tidyr pivot_longer
#' @importFrom tidyselect one_of
#' @import ggplot2
#'
#' @name plotSeqContent
#' @rdname plotSeqContent-methods
#' @export
setGeneric("plotSeqContent", function(x, usePlotly = FALSE, labels, ...){
    standardGeneric("plotSeqContent")
}
)
#' @rdname plotSeqContent-methods
#' @export
setMethod("plotSeqContent", signature = "ANY", function(
    x, usePlotly = FALSE, labels, ...){
    .errNotImp(x)
}
)
#' @rdname plotSeqContent-methods
#' @export
setMethod("plotSeqContent", signature = "character", function(
    x, usePlotly = FALSE, labels, ...){
    x <- FastqcDataList(x)
    if (length(x) == 1) x <- x[[1]]
    plotSeqContent(x, usePlotly, labels, ...)
}
)
#' @rdname plotSeqContent-methods
#' @export
setMethod("plotSeqContent", signature = "FastqcData", function(
    x, usePlotly = FALSE, labels, ...){

    ## Get the SequenceContent
    df <- getModule(x, "Per_base_sequence_content")
    names(df)[names(df) == "Base"] <- "Position"

    if (!length(df)) {
        scPlot <- .emptyPlot("No Sequence Content Module Detected")
        if (usePlotly) scPlot <- ggplotly(scPlot, tooltip = "")
        return(scPlot)
    }

    df$Position <- factor(df$Position, levels = unique(df$Position))

    ## Drop the suffix, or check the alternate labels
    labels <- .makeLabels(x, labels, ...)
    labels <- labels[names(labels) %in% df$Filename]
    acgt <- c("T", "C", "A", "G")

    df$Filename <- labels[df$Filename]
    df <- tidyr::gather(df, "Base", "Percent", one_of(acgt))
    df$Base <- factor(df$Base, levels = acgt)
    df$Percent <- round(df$Percent, 2)
    df$x <- as.integer(df$Position)

    ##set colours
    baseCols <- c(`T` = "red", G = "black", A = "green", C = "blue")

    ## Get any arguments for dotArgs that have been set manually
    dotArgs <- list(...)
    allowed <- names(formals(theme))
    keepArgs <- which(names(dotArgs) %in% allowed)
    userTheme <- c()
    if (length(keepArgs) > 0) userTheme <- do.call(theme, dotArgs[keepArgs])

    xLab <- "Position in read (bp)"
    yLab <- "Percent"
    scPlot <- ggplot(
        df, aes_string("x", "Percent", label = "Position", colour = "Base")
    ) +
        geom_line() +
        facet_wrap(~Filename) +
        scale_y_continuous(
            limits = c(0, 100), expand = c(0, 0), labels = .addPercent
        ) +
        scale_x_continuous(
            expand = c(0, 0),
            breaks = seq_along(levels(df$Position)),
            labels = levels(df$Position)
        ) +
        scale_colour_manual(values = baseCols) +
        guides(fill = FALSE) +
        labs(x = xLab, y = yLab) +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))

    if (usePlotly) {

        ttip <- c("y", "label", "colour")
        scPlot <- plotly::ggplotly(scPlot, tooltip = ttip)
        scPlot <- suppressMessages(
            suppressWarnings(
                plotly::subplot(
                    plotly::plotly_empty(),
                    scPlot,
                    widths = c(0.14,0.86))
            )
        )

        scPlot <- plotly::layout(
            scPlot, xaxis2 = list(title = xLab), yaxis2 = list(title = yLab)
        )
    }

    scPlot

}
)
#' @rdname plotSeqContent-methods
#' @export
setMethod("plotSeqContent", signature = "FastqcDataList", function(
    x, usePlotly = FALSE, labels, pwfCols,
    plotType = c("heatmap", "line", "residuals"),
    cluster = FALSE, dendrogram = FALSE, ..., nc = 2){

    ## Get the SequenceContent
    df <- getModule(x, "Per_base_sequence_content")

    if (!length(df)) {
        scPlot <- .emptyPlot("No Sequence Content Module Detected")
        if (usePlotly) scPlot <- ggplotly(scPlot, tooltip = "")
        return(scPlot)
    }

    ## Convert the Base to Start & End columns
    df$Start <- gsub("([0-9]*)-[0-9]*", "\\1", df$Base)
    df$End <- gsub("[0-9]*-([0-9]*)", "\\1", df$Base)
    df <- mutate_at(df, c("Start", "End"), as.integer)

    plotType <- match.arg(plotType)
    if (missing(pwfCols)) pwfCols <- pwf

    ## Drop the suffix, or check the alternate labels
    labels <- .makeLabels(x, labels, ...)
    labels <- labels[names(labels) %in% df$Filename]

    ## Get any arguments for dotArgs that have been set manually
    dotArgs <- list(...)
    allowed <- names(formals(theme))
    keepArgs <- which(names(dotArgs) %in% allowed)
    userTheme <- c()
    if (length(keepArgs) > 0) userTheme <- do.call(theme, dotArgs[keepArgs])

    ## Define the bases as a vector for ease later in the function
    acgt <- c("T", "C", "A", "G")
    ## Axis labels
    xLab <- "Position in read (bp)"
    yLab <- ifelse(plotType == "heatmap", "Filename", "Percent (%)")

    ## Get the PASS/WARN/FAIL status
    status <- getSummary(x)
    status <- subset(status, Category == "Per base sequence content")

    if (plotType == "heatmap") {

        ## Round to 2 digits to reduce the complexity of the colour
        ## palette
        df <- dplyr::mutate_at(df, acgt, round, digits = 2)
        maxBase <- max(vapply(acgt, function(x){max(df[[x]])}, numeric(1)))
        ## Set the colours, using opacity for G
        df$opacity <- 1 - df$G / maxBase
        df$colour <- with(df, rgb(
            red = `T` * opacity / maxBase,
            green = A * opacity / maxBase,
            blue = C * opacity / maxBase)
        )

        basicStat <- getModule(x, "Basic_Statistics")
        basicStat <- basicStat[c("Filename", "Longest_sequence")]
        df <- dplyr::right_join(df, basicStat, by = "Filename")
        cols <- c("Filename", "Start", "End", "colour", "Longest_sequence")
        df <- df[c(cols, acgt)]

        if (dendrogram && !cluster) {
            message( "cluster will be set to TRUE when dendrogram = TRUE")
            cluster <- TRUE
        }

        ## Now define the order for a dendrogram if required
        key <- names(labels)
        if (cluster) {
            df_gath <- tidyr::gather(df, "Base", "Percent", one_of(acgt))
            df_gath$Start <- paste(df_gath$Start, df_gath$Base, sep = "_")
            df_gath <- df_gath[c("Filename", "Start", "Percent")]
            clusterDend <-
                .makeDendro(df_gath, "Filename", "Start", "Percent")
            key <- labels(clusterDend)
        }
        ## Now set everything as factors
        df$Filename <- factor(labels[df$Filename], levels = labels[key])
        ## Define the colours as named colours (name = colour)
        tileCols <- unique(df$colour)
        names(tileCols) <- unique(df$colour)
        ## Define the tile locations
        df$y <- as.integer(df$Filename)
        df$ymax <- as.integer(df$Filename) + 0.5
        df$ymin <- df$ymax - 1
        df$xmax <- df$End + 0.5
        df$xmin <- df$Start - 1
        df$Position <- ifelse(
            df$Start == df$End,
            paste0(df$Start, "bp"),
            paste0(df$Start, "-", df$End, "bp")
        )
        ## Add percentage signs to ACGT for prettier labels
        df <- dplyr::mutate_at(df, acgt, .addPercent)

        yBreaks <- seq_along(levels(df$Filename))
        scPlot <- ggplot(
            df,
            aes_string(
                fill = "colour",
                A = "A", C = "C", G = "G", `T` = "T",
                Filename = "Filename",
                Position = "Position")) +
            geom_rect(
                aes_string(
                    xmin = "xmin", xmax = "xmax",
                    ymin = "ymin", ymax = "ymax"
                ),
                linetype = 0) +
            scale_fill_manual(values = tileCols) +
            scale_x_continuous(expand = c(0, 0)) +
            scale_y_continuous(
                expand = c(0, 0),
                breaks = yBreaks,
                labels = levels(df$Filename)
            ) +
            theme_bw() +
            theme(legend.position = "none", panel.grid = element_blank()) +
            labs(x = xLab, y = yLab)

        if (!is.null(userTheme)) scPlot <- scPlot + userTheme

        if (usePlotly) {
            scPlot <- scPlot +
                theme(
                    axis.ticks.y = element_blank(),
                    axis.text.y = element_blank(),
                    axis.title.y = element_blank()
                )

            status$Filename <- labels[status$Filename]
            status$Filename <-
                factor(status$Filename, levels = levels(df$Filename))
            sideBar <- .makeSidebar(status, key, pwfCols)

            dendro <- plotly::plotly_empty()
            if (dendrogram) {
                dx <- ggdendro::dendro_data(clusterDend)
                dendro <- .renderDendro(dx$segments)
            }

            ## Render using ggplotly to enable easier tooltip
            ## specification
            scPlot <- plotly::ggplotly(
                scPlot, tooltip = c(acgt, "Filename", "Position")
            )
            ## Now make the complete layout
            scPlot <- suppressWarnings(
                suppressMessages(
                    plotly::subplot(
                        dendro, sideBar, scPlot,
                        widths = c(0.1,0.08,0.82),
                        margin = 0.001, shareY = TRUE)
                )
            )

        }
    }
    if (plotType == "line") {
        df$Filename <- labels[df$Filename]
        df <- df[!colnames(df) == "Base"]
        df <- tidyr::gather(df, "Base", "Percent", one_of(acgt))
        df$Base <- factor(df$Base, levels = acgt)
        df$Percent <- round(df$Percent, 2)
        df$Position <- ifelse(
            df$Start == df$End,
            as.character(df$Start),
            paste0(df$Start, "-", df$End)
        )
        posLevels <- stringr::str_sort(unique(df$Position), numeric = TRUE)
        df$Position <- factor(df$Position, levels = posLevels)
        df$x <- as.integer(df$Position)

        ## Add the pwf status for plotly plots
        status[["Filename"]] <- labels[status[["Filename"]]]
        df <- left_join(df, status, by = "Filename")
        rect_df <- group_by(df, Filename, Status)
        rect_df <- dplyr::summarise(
            rect_df,
            Start = 0,
            End = length(levels(Position)),
            .groups = "drop"
        )

        ##set colours for each base
        baseCols <- c(`T` = "red", G = "black", A = "green", C = "blue")

        xBreaks <- seq_along(levels(df$Position))
        scPlot <- ggplot(
            df,
            aes_string("x", "Percent", colour = "Base", label = "Position")
        ) +
            geom_rect(
                aes_string(
                    xmin = 0, xmax = "End" ,
                    ymin = 0, ymax = 100, fill = "Status"
                ),
                data = rect_df,
                alpha = 0.1,
                inherit.aes = FALSE
            ) +
            geom_line() +
            facet_wrap(~Filename, ncol = nc) +
            scale_y_continuous(
                limits = c(0, 100), expand = c(0, 0), labels = .addPercent
            ) +
            scale_x_continuous(
                expand = c(0, 0),
                breaks = xBreaks,
                labels = levels(df$Position)
            ) +
            scale_fill_manual(values = getColours(pwfCols)) +
            scale_colour_manual(values = baseCols) +
            labs(x = xLab, y = yLab) +
            theme_bw() +
            theme(
                axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)
            )


        if (!is.null(userTheme)) scPlot <- scPlot + userTheme

        if (usePlotly) {
            scPlot <- scPlot + theme(legend.position = "none")
            ttip <- c("y", "colour", "label", "fill")
            scPlot <- suppressMessages(
                suppressWarnings(plotly::ggplotly(scPlot, tooltip = ttip))
            )
        }
    }
    if (plotType == "residuals"){

        df$Filename <- labels[df$Filename]
        ## Fill in the values glossed over by any binning by FastQC
        df <- lapply(
            split(df, f = df$Filename),
            function(x){
                x <- dplyr::right_join(
                    x = x,
                    y = tibble(Start = seq_len(max(x$Start))),
                    by = "Start"
                )
                x <- dplyr::arrange(x, Start)
                x <- dplyr::mutate(
                    x,
                    dplyr::across(
                        .cols = c(acgt, Filename),
                        .fns =  na.locf
                    )
                )
                x <- dplyr::arrange(x, Start)
            }
        )
        df <- dplyr::bind_rows(df)[,c("Filename", "Start", acgt)]
        ## Convert to long form
        df <- pivot_longer(
            data = df,
            cols = acgt,
            names_to = "Base",
            values_to = "Percent"
        )
        ## Avoid R CMD check error
        Status <- End <- Percent <- c()
        ## Calculate the Residuals for each base/position
        df <- group_by(df, Start, Base)
        df <- dplyr::mutate(df, Residuals = Percent - mean(Percent))
        df <- ungroup(df)
        df[["Residuals"]] <- round(df[["Residuals"]], 2)
        ## Find the duplicated positions as a result of binning & remove
        df <- dplyr::arrange(df, Filename, Base, Start)
        df <- group_by(df, Filename, Base)
        df <- dplyr::mutate(df, diff = c(0, diff(Percent)))
        df <- ungroup(df)
        df <- dplyr::filter(df, diff != 0 | Start == 1)
        df[["Deviation"]] <- percent(df[["Residuals"]]/100, accuracy = 0.1)
        ## Add the pwf status for plotly plots
        status[["Filename"]] <- labels[status[["Filename"]]]
        df <- left_join(df, status, by = "Filename")

        scPlot <- ggplot(
            df,
            aes_string(
                x = "Start", y = "Residuals",
                colour = "Filename", label = "Deviation",
                status = "Status"
            )
        ) +
            geom_line(aes_string(group = "Filename")) +
            facet_wrap(~Base) +
            scale_y_continuous(labels = .addPercent) +
            labs(x = xLab) +
            theme_bw()

        if (!is.null(userTheme)) scPlot <- scPlot + userTheme

        if (usePlotly) {
            ttip <- c("x", "colour", "label", "status")
            scPlot <- scPlot + theme(legend.position = "none")
            scPlot <- suppressMessages(
                suppressWarnings(
                    plotly::ggplotly(scPlot, tooltip = ttip)
                )
            )
        }


    }

    scPlot
}
)
