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
import subprocess

from utils import logger


class DpFrEP:
    """
    This is a class for DpFrEP module.
    """

    @staticmethod
    def execute_dpfrep_rscript(expression_matrix, reference_ids, arguments, input_r_script_path):
        """
        Execute DpFrEP.

        :param expression_matrix: Path of input CSV file
        :type expression_matrix: str
        :param reference_ids: Path of input CSV file
        :type reference_ids: str
        :param arguments: Dict containing tool arguments
        :type arguments: dict
        :param input_r_script_path: Path of R script file
        :type input_r_script_path: str
        """
        logger.debug("Starting DpFrEP execution")
        args_list = list(arguments.values())

        print(args_list)

        cmd = [
            '/usr/bin/Rscript',
            '--vanilla',
            input_r_script_path,
            expression_matrix,
            reference_ids,
            str(args_list[3]),
            str(args_list[4])
        ]

        print(cmd)

        # process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # return process
        pass
