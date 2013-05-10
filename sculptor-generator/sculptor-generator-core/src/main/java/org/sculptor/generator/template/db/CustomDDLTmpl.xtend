/*
 * Copyright 2007 The Fornax Project Team, including the original 
 * author or authors.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.sculptor.generator.template.db

import javax.inject.Inject
import org.sculptor.generator.util.HelperBase
import sculptormetamodel.Application

class CustomDDLTmpl {

	@Inject extension HelperBase helperBase

/*CustomDDL.xpt is only a placeholder that is intended to be 
	overridden by placing a custom template with the same name
	in the classpath. See Developer's Guide.
 */
def String ddl(Application it) {
	'''
	�error("CustomDDL.xpt is intended to be overridden by placing a custom template with the same name in the classpath.")�
	'''
}

}