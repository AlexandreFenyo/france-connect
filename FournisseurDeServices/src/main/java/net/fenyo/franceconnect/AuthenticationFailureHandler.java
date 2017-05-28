package net.fenyo.franceconnect;

/*
 * Copyright 2016 Alexandre Fenyo - alex@fenyo.net - http://fenyo.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.ExceptionMappingAuthenticationFailureHandler;

public class AuthenticationFailureHandler extends ExceptionMappingAuthenticationFailureHandler {
	private static final Logger logger = LoggerFactory.getLogger(AuthenticationFailureHandler.class);

	@Override
	public void onAuthenticationFailure(final HttpServletRequest request, final HttpServletResponse response, final AuthenticationException exception) throws IOException, ServletException {
		Tools.log("authentication failure exception: [" + exception + "]", request, null, logger);
		super.onAuthenticationFailure(request, response, exception);
	}
}
