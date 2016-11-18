#!/usr/bin/python

"""
script to render jinja template with env variables and output rendered file.
"""

import sys, os, argparse
from argparse import RawTextHelpFormatter
from jinja2 import Template, TemplateSyntaxError


def replace_variables(variable):
    """This function replaces all variables in a string by the corresponding environment variables values.
    Args:
        variable (str): String containing several variables (e.g. $TEST=test1, $TEST2, test3).
    Returns:
        str: variable with replaced environment variables.
    """
    while variable[1].find("$") != -1:
        startPoint = variable[1].find("$")
        endPoint = startPoint + 1

        # Find end point of variable. Allowed characters are [A-Z] and "_"
        while ((ord(variable[1][endPoint]) >= 65 and ord(variable[1][endPoint]) <= 90) or ord(variable[1][endPoint]) == 95):
            endPoint += 1
            # Break loop if end of line is reached
            if not(endPoint < len(variable[1])):
                break

        envVariableKey = variable[1][startPoint+1:endPoint]

        if len(envVariableKey) < 2:
            print("Environment variable name is empty.")
            sys.exit(1)

        variable[1] = variable[1].replace("$" + envVariableKey, os.environ.get(envVariableKey), 1)

    return(variable)


def add_variable(verbose, templateVariables, variable):
    """This function adds a given variable to the templateVariables.
    Args:
        templateVariables (dict): Dictionary storing all templateVariables.
        variable (str): String containing the variable that should be added.
    Returns:
        dict: templateVariables with added new variable.
    """
    variable = variable.split("=")

    if len(variable) < 2:
        envVariable = os.environ.get(variable[0])
        if verbose:
            if envVariable == None:
                print("    Env variable {0} is not set.".format(variable[0]))
            else:
                print("    {0}={1}".format(variable[0], envVariable))
        templateVariables[variable[0]] = os.environ.get(variable[0])
    else:
        if verbose:
            print("    {0}={1}".format(variable[0], variable[1]))
        # Replacing variables in string by values from environment variables.
        variable = replace_variables(variable)
        templateVariables[variable[0]] = variable[1]

    return(templateVariables)


def generate_template_variables(verbose, args):
    """This function generates the variables used to fill the templates.
    Args:
        args (dict): Parsed arguments passed by the program call.
    Returns:
        dict: Variables used to fill the templates. ({<variable name>: <value>, ...})
    Examples:
        {"HOME": "/bin/java", "ENV_URL": "http://jenkins.intern.epages.de:8080"}
    """
    templateVariables = dict()

    # Get and store passed environment variables.
    if args.env != None:
        if verbose:
            print("Fetch variables from --env:")
        for variable in args.env:
            templateVariables = add_variable(verbose, templateVariables, variable)

    # Get and store variables from passed files.
    if args.files != None:
        if verbose:
            print("Fetch variables from --env-file:")
        for file in args.files:
            try:
                variableFile = open(file, "r")
            except IOError as e:
                print("Could not open file. Message: {0}".format(e.strerror))
                sys.exit(1)
            except Exception as e:
                print("An unexpected Error has occurred: {0}".format(e))
                sys.exit(1)
            for line in variableFile:
                line = line.replace("\r", "")
                line = line.replace("\n", "")
                line = line.replace(" ", "")
                if len(line) > 0:
                    if line[0] != "#":
                        templateVariables = add_variable(verbose, templateVariables, line)
            variableFile.close()

    return(templateVariables)


def render_template(verbose, templatePath, templateVariables, destDir):
    """This function renders one template.
    Args:
        templatePath (str): Path to access the template that should be rendered.
        templateVariables (dict): Variables to fill into the template. ({<variable name>: <value>, ...})
        destDir (str): Path to the destination folder.
    Examples:
        {"HOME": "/bin/java", "ENV_URL": "http://jenkins.intern.epages.de:8080"}
    """
    try:
        templateFile = open(templatePath, "r")
        template = Template(templateFile.read())
        templateFile.close()
    except IOError as e:
        print("Could not read template file {0}. Error: {1}".format(templatePath, e.strerror))
        sys.exit(1)
    except TemplateSyntaxError as e:
        print("Jinja2 template has an Syntax Error. Message: {0}".format(e.message))
        sys.exit(1)
    except TemplateNotFound as e:
        print("Jinja2 template could not be found. Message: {0}".format(e.message))
        sys.exit(1)
    except Exception as e:
        print("An unexpected Error has occurred: {0}".format(e))
        sys.exit(1)

    # Cut the file ending '.j2' so the template will not be overwritten.
    templatePath = templatePath[0:len(templatePath)-3]

    if destDir != "":

        if destDir[-1] != "/":
            destDir += "/"

        # Create destination directory if it does not exists.
        if not os.path.exists(destDir):
            try:
                os.makedirs(destDir)
            except IOError as e:
                print("Could not create directory {0}. Error: {1}".format(destDir, e.strerror))
                sys.exit(1)
            except Exception as e:
                print("An unexpected Error has occurred: {0}".format(e))
                sys.exit(1)

        # Use only filename if new destination folder should be used.
        templatePath = templatePath.split("/")[-1]

    try:
        renderedTemplate = template.render(templateVariables)
        if verbose:
            print("Render variables in given jinja templates and output dest files:\n    {0}".format(destDir + templatePath))
        confFile = open(destDir + templatePath, "w")
        confFile.write(renderedTemplate)
        confFile.close()
    except IOError as e:
        print("Could not create rendered template file {0}. Error: {1}".format(destDir + templatePath, e.strerror))
        sys.exit(1)
    except TypeError as e:
        print("There has been an error within your template: Error: {0}".format(e.message))
        sys.exit(1)
    except Exception as e:
        print("An unexpected Error has occurred: {0}".format(e))
        sys.exit(1)


def main():
    """This function renders each template with the given variables.
    Args:
        args (dict): Parsed arguments passed by the program call.
    """

    # parse arguments
    parser = argparse.ArgumentParser(
        description='script to render jinja template with env variables and output rendered file.',
        epilog='''
hints:
  - It is required to set at least one of the args: --e, --env or -f, --env-file
  - The jinja template name must end with ext *.j2
  - The rendererd output file has the same filename without ext *.j2
  - If the same key is passed by --env and --env-file, the key-value from the --env-file is rendered.
invocation:
  render_jinja_template.py -v -t <filename>.<ext>.j2 -e <key> <key>=<value> -f <env.list> -d </dest/dir>
  render_jinja_template.py --verbose --template <filename>.<ext>.j2 --env <key> <key>=<value> --env-file <env.list> --dest </dest/dir>
examples:
  render_jinja_template.py -t template.txt.j2 -e HOME ENV_URL=www.test.de
  render_jinja_template.py -t template.txt.j2 -e HOME ENV_URL -f variable_store.txt -d conf/
  render_jinja_template.py -t template1.txt.j2 template2.txt.j2 -f variable_store1.list variable_store2.list
example of ENV_FILE contents:
  # comment
  KEY
  HOME
  # key-value-pairs
  KEY=VALUE
  ENV_URL="http://www.jenkins.intern.epages.de:8080/"
    ''', formatter_class=RawTextHelpFormatter)
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='run in verbose mode')
    parser.add_argument('-e', '--env', dest='env', nargs='+', required=False,
                        help='''pass env variables as <key> or <key>=<value>''')
    parser.add_argument('-f', '--env-file', dest='files', nargs='+', required=False,
                        help='''pass env variables from files containing a list of <key> and <key>=<value>''')
    parser.add_argument('-t', '--template', dest='templates', nargs='+', required=True, help='render jinja template(s)')
    parser.add_argument('-d', '--dest', dest='dest', required=False, default="", help='set destination directory for ouput file(s)')
    args = parser.parse_args()

    # define script variables
    verbose = args.verbose
    env_variables = args.env
    env_files = args.files
    templates = args.templates
    dest_dir=args.dest

    if env_files != None:
        # Test if one of the given files is a directory
        for file in env_files:
            if os.path.isdir(file):
                print("One of the given files is a directory!")
                sys.exit(1)

    # Test if one of the given templates is a directory
    for template in templates:
        if os.path.isdir(template):
            print("One of the given templates is a directory!")
            sys.exit(1)

    if env_variables == None and env_files == None:
        print("At least one of the flags --env or --env-file must be set!")
    else:
        for template in templates:
            # If one of the template file names does not end with .j2 exit with error.
            if template[-3:len(template)] != ".j2":
                print("One of the files is no template file. Please do only insert files ending with *.j2")
                sys.exit(1)
        templateVariables = generate_template_variables(verbose, args)
        for template in templates:
            render_template(verbose, template, templateVariables, dest_dir)

if __name__ == '__main__':
    """
    start here
    """
    main()
