#!/usr/bin/env python

"""
.. See the NOTICE file distributed with this work for additional information
   regarding copyright ownership.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""
import os
import time

from basic_modules.tool import Tool
from utils import logger
from lib.dpfrep import DpFrEP  # TODO change


class RUNNER(Tool):
    """
    This is a class for DpFrEP Tool module.
    """

    MASKED_KEYS = {'execution', 'project', 'description', 'reference_ids',
                   'file_type'}  # TODO add arguments from config.json
    R_SCRIPT_PATH = "/home/user/vre_dpfrep_executor/lib/run_dpfrep.r"  # TODO change
    debug_mode = False  # If True debug mode is on, False otherwise

    def __init__(self, configuration=None):
        """
        Init function
        """
        logger.debug("VRE DpFrEP runner")  # TODO change
        Tool.__init__(self)

        if configuration is None:
            configuration = {}

        self.configuration.update(configuration)

        # Arrays are serialized
        for k, v in self.configuration.items():
            if isinstance(v, list):
                self.configuration[k] = ' '.join(v)

        self.dpfrep = DpFrEP()  # TODO change
        self.outputs = dict()
        self.execution_path = None

    def execute_dpfrep(self, input_files, arguments):  # pylint: disable=no-self-use
        """
        The main function to run the remote DpFrEP

        param input_files: List of input files - In this case there are no input files required.
        :type input_files: dict
        :param arguments: Dict containing tool arguments
        :type arguments: dict
        """
        try:
            logger.debug("Getting CSV or TSV input file")
            file_input_path = input_files["expression_matrix"]  # TODO change from input_files config.json

            if file_input_path is None:
                errstr = "CSV or TSV input file must be defined"
                logger.fatal(errstr)
                raise Exception(errstr)

            print(arguments)

            # DpFrEP execution
            process = self.dpfrep.execute_dpfrep_rscript(file_input_path, arguments, self.R_SCRIPT_PATH)  # TODO change

            # Sending the DpFrEP execution stdout to the log file
            for line in iter(process.stderr.readline, b''):
                print(line.rstrip().decode("utf-8").replace("", " "))

            rc = process.poll()
            while rc is None:
                rc = process.poll()
                time.sleep(0.1)

            if rc is not None and rc != 0:
                logger.progress("Something went wrong inside the R execution. See logs", status="WARNING")

            else:
                logger.progress("DpFrEP execution finished successfully", status="FINISHED")

        except:
            errstr = "The DpFrEP execution failed. See logs"
            logger.error(errstr)
            raise Exception(errstr)

    def run(self, input_files, input_metadata, output_files, output_metadata):
        """
        The main function to run the compute_metrics tool.

        :param input_files: List of input files - In this case there are no input files required.
        :type input_files: dict
        :param input_metadata: Matching metadata for each of the files, plus any additional data.
        :type input_metadata: dict
        :param output_files: List of the output files that are to be generated.
        :type output_files: dict
        :param output_metadata: List of matching metadata for the output files
        :type output_metadata: list
        :return: List of files with a single entry (output_files), List of matching metadata for the returned files
        (output_metadata).
        :rtype: dict, dict
        """
        try:

            # Set and validate execution directory. If not exists the directory will be created.
            execution_path = os.path.abspath(self.configuration.get('execution', '.'))
            self.execution_path = execution_path  # save execution path
            if not os.path.isdir(self.execution_path):
                os.makedirs(self.execution_path)

            # Set and validate execution parent directory. If not exists the directory will be created.
            execution_parent_dir = os.path.dirname(self.execution_path)
            if not os.path.isdir(execution_parent_dir):
                os.makedirs(execution_parent_dir)

            # Update working directory to execution path
            os.chdir(self.execution_path)
            logger.debug("Execution path: {}".format(self.execution_path))

            logger.debug("DpFrEP execution")
            self.execute_dpfrep(input_files, self.configuration)  # TODO change

            # Create and validate the output files
            self.create_output_files(output_files, output_metadata)
            logger.debug("Output files and output metadata created")

            return output_files, output_metadata

        except:
            errstr = "VRE dpfrep RUNNER pipeline failed. See logs"
            logger.fatal(errstr)
            raise Exception(errstr)

    def create_output_files(self, output_files, output_metadata):  # TODO add from output_files config.json
        """
        Create output files list

        :param output_files: List of the output files that are to be generated.
        :type output_files: dict
        :param output_metadata: List of matching metadata for the output files
        :type output_metadata: list
        :return: List of files with a single entry (output_files), List of matching metadata for the returned files
        (output_metadata).
        :rtype: dict, dict
        """
        try:
            global file_path
            drug_ranked = self.configuration.get('drug_ranked_list', '.')  # TODO add new output files

            for metadata in output_metadata:  # for each output file in output_metadata
                out_id = metadata["name"]
                pop_output_path = list()  # list of tuples (path, type of output)
                if out_id in output_files.keys():
                    # if out_id == "drug_ranked_list": optional
                    # TODO change if yoy want to change the name of the output file
                    file_path = self.execution_path + "/" + out_id + "_" + drug_ranked.replace(' ', '') + ".csv"

                    pop_output_path.append((file_path, "file"))  # add file_path and file_type

                    output_files[out_id] = pop_output_path  # create output files
                    self.outputs[out_id] = pop_output_path  # save output files

        except:
            errstr = "Output files not created. See logs"
            logger.fatal(errstr)
            raise Exception(errstr)
