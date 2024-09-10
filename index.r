library(flowCore)
library(jsonlite)

# Function to update specific parameters, flip -W and -H suffixes, and rename keywords in the FCS file
update_fcs_parameters <- function(fcs_file, output_dir, config) {
    # Read the FCS file
    samp <- read.FCS(fcs_file)

    # Extract settings from the config
    param_replacements <- config$parameter_replacements
    flip_width_height <- config$flip_width_height

    # Function to flip -H and -W suffixes if the flag is set
    flip_suffix <- function(name) {
        if (flip_width_height) {
            if (grepl("-H$", name)) {
                sub("-H$", "-W", name)
            } else if (grepl("-W$", name)) {
                sub("-W$", "-H", name) # nolint
            } else {
                name
            }
        } else {
            name
        }
    }

    # Create a map to store the old names and their corresponding new names
    name_map <- list()

    # First loop: create the map of old names to new names
    for (i in seq_len(length(samp@parameters@data$desc))) {
        old_name <- samp@parameters@data$name[i]

        # Determine the new name
        if (old_name %in% names(param_replacements)) {
            new_name <- param_replacements[[old_name]]
        } else {
            new_name <- flip_suffix(old_name)
        }

        # Store in the map
        name_map[[old_name]] <- new_name
    }

    # Update colnames of the expression matrix and pData as a whole
    updated_names <- unlist(name_map)
    colnames(samp) <- updated_names
    samp@parameters@data$name <- updated_names

    # Update keywords in the description slot
    for (i in seq_len(length(updated_names))) {
        kw_param_name <- paste0("$P", i, "N")
        samp@description[[kw_param_name]] <- updated_names[i]
    }

    # Update SPILL and SPILLOVER matrices if present
    if ("SPILL" %in% names(samp@description)) {
        spill_colnames <- colnames(samp@description$SPILL)
        for (j in seq_along(spill_colnames)) {
            old_name <- spill_colnames[j]
            if (old_name %in% names(name_map)) {
                colnames(samp@description$SPILL)[j] <- name_map[[old_name]]
            }
        }
    }

    if ("SPILLOVER" %in% names(samp@description)) {
        spillover_colnames <- colnames(samp@description$SPILLOVER)
        for (j in seq_along(spillover_colnames)) {
            old_name <- spillover_colnames[j]
            if (old_name %in% names(name_map)) {
                colnames(samp@description$SPILLOVER)[j] <- name_map[[old_name]]
            }
        }
    }

    # Update the internal filename to the actual file name (without extension)
    file_name_without_ext <- tools::file_path_sans_ext(basename(fcs_file))
    samp@description[["$FIL"]] <- paste0(file_name_without_ext, ".fcs")

    # Create the output directory if it doesn't exist
    if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    # Create the new file path in the subdirectory
    new_file_path <- file.path(output_dir, paste0(file_name_without_ext, ".fcs"))

    # Save the modified FCS file in the subdirectory
    write.FCS(samp, new_file_path)

    cat(paste("Processed and saved:", new_file_path, "\n"))
}

# Load the configuration from the JSON file
config <- fromJSON("config.json")

# Path to the folder containing the FCS files
folder_path <- "./data"

# Path to the subdirectory where flipped files will be saved
output_subdir <- file.path("./", "updated_fcs")

# Get a list of all FCS files in the folder
fcs_files <- list.files(folder_path, pattern = "\\.fcs$", full.names = TRUE)

# Apply the flipping function to each file, using the config settings and saving the result in the subdirectory
lapply(fcs_files, update_fcs_parameters, output_dir = output_subdir, config = config)

cat("Parameter name flipping completed for all files.\n")
