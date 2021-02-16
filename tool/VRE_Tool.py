#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright 2020-2021 Barcelona Supercomputing Center (BSC), Spain
# Copyright 2020-2021 University of Naples (UNINA), Italy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import subprocess
import time

from basic_modules.tool import Tool
from utils import logger


class myTool(Tool):
    """
    This class define DpFrEP Tool.
    """
    DEFAULT_KEYS = ['execution', 'project', 'description']  # config.json default keys
    R_SCRIPT_PATH = "R/run_dpfrep.R"

    def __init__(self, configuration=None):
        """
        Init function

        :param configuration: a dictionary containing parameters that define how the operation should be carried out,
        which are specific to DpFrEP tool.
        :type configuration: dict
        """
        Tool.__init__(self)

        if configuration is None:
            configuration = {}

        self.configuration.update(configuration)

        for k, v in self.configuration.items():
            if isinstance(v, list):
                self.configuration[k] = ' '.join(v)

        # Init variables
        self.execution_path = os.path.abspath(self.configuration.get('execution', '.'))
        self.arguments = dict(
            [(key, value) for key, value in self.configuration.items() if key not in self.DEFAULT_KEYS]
        )

    def run(self, input_files, input_metadata, output_files, output_metadata):
        """
        The main function to run the DpFrEP tool.

        :param input_files: Dictionary of input files locations.
        :type input_files: dict
        :param input_metadata: Dictionary of files metadata.
        :type input_metadata: dict
        :param output_files: Dictionary of the output files locations. expected to be generated.
        :type output_files: dict
        :param output_metadata: # TODO
        :type output_metadata: list
        :return: # TODO
        :rtype: dict, dict
        """
        try:
            # Set and validate execution directory. If not exists the directory will be created.
            if not os.path.isdir(self.execution_path):
                os.makedirs(self.execution_path)

            # Set and validate execution parent directory. If not exists the directory will be created.
            execution_parent_dir = os.path.dirname(self.execution_path)
            if not os.path.isdir(execution_parent_dir):
                os.makedirs(execution_parent_dir)

            # Update working directory to execution path
            os.chdir(self.execution_path)

            # Tool Execution
            self.toolExecution(input_files)

            # Create and validate the output files from tool execution
            self.createOutput(output_files, output_metadata)

            return output_files, output_metadata

        except:
            errstr = "VRE DpFrEP tool execution failed. See logs."
            logger.fatal(errstr)
            raise Exception(errstr)

    def toolExecution(self, input_files):
        """
        The main function to run the DpFrEP tool.

        :param input_files: Dictionary of input files locations.
        :type input_files: dict
        """
        try:
            # Get input files
            expression_matrix = input_files.get("expression_matrix")

            # Get arguments
            tumor_type = self.arguments.get("tumor_type")
            model = self.arguments.get("model")

            # Rscript execution
            cmd = [
                '/usr/bin/Rscript',
                '--vanilla',
                self.R_SCRIPT_PATH,
                expression_matrix,
                tumor_type,
                model
            ]

            print(cmd)
            # process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            #
            # # Sending the stdout to the log file
            # for line in iter(process.stderr.readline, b''):
            #     print(line.rstrip().decode("utf-8").replace("", " "))
            #
            # rc = process.poll()
            # while rc is None:
            #     rc = process.poll()
            #     time.sleep(0.1)
            #
            # if rc is not None and rc != 0:
            #     logger.progress("Something went wrong inside the Rscript execution. See logs.", status="WARNING")
            # else:
            #     logger.progress("The Rscript execution finished successfully.", status="FINISHED")

        except:
            errstr = "The Rscript execution failed. See logs."
            logger.error(errstr)
            raise Exception(errstr)

    def createOutput(self, output_files, output_metadata):
        """
        Set output files of Rscript execution

        :param output_files: # TODO
        :type output_files: # TODO
        :param output_metadata: List of matching metadata for the output files
        :type output_metadata: list
        :return: # TODO
        :rtype: dict, dict
        """
        try:
            for metadata in output_metadata:
                output_id = metadata["name"]
                outputs = list()  # list of tuples (path, type of output)
                if output_id in output_files.keys():
                    file_path = self.execution_path + "/" + output_id + ".xlsx"
                    outputs.append((file_path, "file"))
                    output_files[output_id] = outputs

            print(output_files)
            print(output_metadata)

        except:
            errstr = "Output files not created. See logs."
            logger.fatal(errstr)
            raise Exception(errstr)
