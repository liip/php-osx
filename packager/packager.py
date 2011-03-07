#!/usr/bin/env python
import sys, tarfile, getopt, urllib, ConfigParser, os, os.path
import re, itertools

class Cli(object):
    """Interactions with the command line."""
    
    def run(self):
        """
        Read the command line options and execute the appropriate
        commands.
        """
        # Get superset of all long options
        long_options = set()
        for option_arr in [globals()[module]().options().keys()
                           for module in globals()
                           if module[0:7] == 'Command']:
            long_options.update(option_arr)
        long_options = list(long_options)
        
        options, args = getopt.gnu_getopt(sys.argv[1:], '', long_options)
        if len(args) == 0:
            self.usage()
        command = args[0]
        params = args[1:]
        cmd_class = globals().get('Command' + command.capitalize(), None)
        if cmd_class is None:
            self.usage()
        cmd_obj = cmd_class()
        if len(args) <= cmd_obj.minargs():
            self.usage()
        
        # Verify that no invalid options were used for this command
        cmd_options = cmd_obj.options().keys()
        for opt in options:
            # opt is a tuple ('--format', '')
            if opt[0][2:] not in cmd_options and opt[0][2:] + '=' not in cmd_options:
                print "ERROR: Option %s is not valid for command %s\n" % (opt[0], command)
                self.usage()
        
        cmd_obj.run(self, params, options)
    
    def usage(self):
        """Prints usage information."""
        msg = "Usage: %s [options] command packages...\n\nAvailable commands with their options:"
        print msg % sys.argv[0]
        prefix = "   "
        for command, cmd in [(module[7:].lower(), globals()[module]())
                        for module in globals()
                        if module[0:7] == 'Command']:
            print prefix, command + ': ', cmd.info()
            for opt, opt_info in cmd.options().iteritems():
                print ' ' * 6 + '--' + opt + ': ' + opt_info
        sys.exit(1)


class BaseCommand(object):
    """Base class for all commands."""
    def info(self):
        """Description for usage."""
        pass
    
    def options(self):
        """
        Returns a dictionary with all allowed command line options for this
        command.
        """
        pass
    
    def minargs(self):
        """Returns the number of free arguments required."""
        return 1
    
    def run(self, cli, params, options):
        """Executes this command."""
        pass


class CommandInfo(BaseCommand):
    def info(self):
        return "Gives information about a package."
    
    def options(self):
        return {
            'format=': "Format for the output. Can be 'brief' or 'full'. 'full' is the default."
        }
    
    def run(self, cli, params, options):
        format = 'full'
        for opt in options:
            if opt[0] == '--format':
                format = opt[1]
        
        for param in params:
            pkg = Package(param)
            info = pkg.info()
            if info:
                if format == 'brief':
                    self.__briefOutput(info)
                else:
                    self.__fullOutput(info)
    
    def __briefOutput(self, info):
        print info.get('name', 'NO NAME') + ': ' + info.get('version', 'NO VERSION')
    
    def __fullOutput(self, info):
        # Defines the order in which we want to show the keys
        keys = ['name', 'version']
        
        # Calculate max key length for nice tabulation
        maxlen = 0
        for key in info:
            if len(key) > maxlen:
                maxlen = len(key)
        
        msg = " %" + str(maxlen) + "s: %s"
        
        # Output all known keys first in correct order.
        # Then the other keys in internal dictionary order.
        for key in keys:
            if key in info:
                print msg % (key, info[key])
                del info[key]
        for key, value in info.iteritems():
            print msg % (key, value)


class CommandInstall(BaseCommand):
    def info(self):
        return "Installs a package and all its dependencies."
    
    def options(self):
        return {
            'root=': "Root directory to install the package into. Useful for testing."
        }
    
    def run(self, cli, params, options):
        root = '/'
        for opt in options:
            if opt[0] == '--root':
                root = opt[1]
        
        registry = PackageRegistry()
        for param in params:
            pkg = Package(param)
            pkg.install(root, registry)
        registry.save()


class CommandList(BaseCommand):
    def info(self):
        return "Lists all installed packages."
    
    def options(self):
        return {}
    
    def minargs(self):
        return 0
    
    def run(self, cli, params, options):
        registry = PackageRegistry()
        
        # Calculate max key length for nice tabulation
        maxlen = 0
        for key in registry.packages:
            if len(key) > maxlen:
                maxlen = len(key)
        msg = "%" + str(maxlen) + "s: %s"
        for pkg, versions in registry.packages.iteritems():
            print msg % (pkg, ", ".join(versions))


class Package(object):
    """
    Represents a single package with the information.
    Transparently handles fetching the package from network.
    """
    def __init__(self, name):
        self.__name = name
        self.__filename = ''
        self.__file = None
        self.__fetch(name)
    
    def info(self):
        """Returns information about this package as a dictionary."""
        member = None
        if not self.__file:
            print "ERROR: Could not download package: %s" % self.__name
            return
        for key in self.__file.getnames():
            modkey = key.replace('./', '')
            if modkey == 'pkg/info':
                member = self.__file.getmember(key)
                break
        if member is None:
            print "ERROR: pkg/info file not found in package %s" % self.__name
            return
        elif not member.isreg():
            print "ERROR: Found pkg/info in package %s, but it's not a file." % self.__name
            return
        member = self.__file.extractfile(member)
        self.__info = self.__parseInfo(member)
        return self.__info
    
    def install(self, root, registry):
        """Installs this package, resolving any dependencies if necessary."""
        print 'Installing package %s into root %s' % (self.__name, root)
        info = self.info()
        curr_version = registry.isInstalled(info['name'], info['version'])
        self._installDependencies(root, registry)
        if curr_version:
            print "Package %s is already installed at version %s. You wanted to install version %s." % (
                info['name'], curr_version, info['version'])
            return
        if not os.path.exists(root):
            os.makedirs(root, 0755)
        if not os.path.isdir(root):
            print "ERROR: %s is not a directory. Aborting installation."
            return

        # Special files we need later
        fnames = {}

        # Extract pre-install script and execute it
        for preinstall in ('./pkg/pre-install', 'pkg/pre-install'):
            print preinstall
            try:
                member = self.__file.getmember(preinstall)
            except KeyError:
                continue
            fnames['pre-install'] = self.__getPostScript(self.__file,
                preinstall, info['name'])
            self.__executePostScript(fnames, 'pre-install')
        
        for key in self.__file.getnames():
            modkey = key.replace('./', '').replace('//', '/')
            member = self.__file.getmember(key)
            if modkey == '/' or modkey.find('/._') > -1 or modkey[0:4] == 'pkg/':
                # Internal file
                if modkey == 'pkg/post-install':
                    fnames['post-install'] = self.__getPostScript(self.__file, key, info['name'])
                elif modkey == 'pkg/post-initial':
                    fnames['post-initial'] = self.__getPostScript(self.__file, key, info['name'])
                else:
                    # Just ignore control files
                    pass
            elif member.isdir() and os.path.exists(os.path.join(root, key)):
                print "Skipping existing directory %s" % modkey
            else:
                print "Extracting %s" % modkey
                dest = os.path.join(root, key)
                if os.path.islink(dest) or (os.path.exists(dest) and
                        member.issym() or member.islnk()):
                    os.unlink(dest)
                self.__file.extract(key, root)
        
        self.__executePostScript(fnames, 'post-initial', not self.__name in registry.packages)
        self.__executePostScript(fnames, 'post-install')
        registry.register(info['name'], info['version'])
    
    def _installDependencies(self, root, registry):
        """Install all required dependencies for this package."""
        self.__installDependenciesRPM(root, registry)
        self.__installDependenciesPackager(root, registry)
    
    def __installDependenciesPackager(self, root, registry, deps_seen=[]):
        """
        Install all required dependencies of the packager format for this
        package.
        """
        deps = self.info().get('depends', [])
        for dep in deps:
            pkg_name, version = self.__dependencyInstalled(dep, registry)
            if version:
                if pkg_name not in deps_seen:
                    pkg = Package(pkg_name)
                    deps_seen.append(pkg_name)
                    pkg._installDependencies(root, registry)
            else:
                print "=" * 80
                print "Installing dependency: %s" % dep
                pkg = Package(pkg_name)
                pkg.install(root, registry)
                print "=" * 80
    
    def __installDependenciesRPM(self, root, registry):
        deps = self.info().get('depends-rpm', [])
        if not deps:
            return
        deps = ' '.join(deps)
        print "Installing RPM dependencies: %s" % deps
        retval = os.system("yum -y install " + deps)
        if retval != 0:
            msg = "ERROR: The yum command returned an invalid return code: %d." % retval
            print msg
            raise Exception(msg)
    
    def __dependencyInstalled(self, package, registry):
        """
        Checks if the given dependency is installed.
        Interprets the dependency strings with optional version number.
        """
        vmatch = re.match('(.+)\((<|<=|>|>=|=)([^\)]+)\)', package)
        if vmatch:
            package = vmatch.group(1).strip()
            operator = vmatch.group(2).strip()
            version = vmatch.group(3).strip()
            return (package, registry.isInstalled(package, version, operator))
        else:
            # Need the latest version
            package = package.strip()
            if not package in registry.packages:
                return (package, False)
            else:
                pkg = Package(package)
                info = pkg.info()
                version = info['version']
                return (package, registry.isInstalled(package, version, '>='))
    
    def __parseInfo(self, file):
        """Parses an info document passed in as a file object."""
        options = {
            'depends': [],
            'depends-rpm': [],
        }
        for line in file.readlines():
            line = line.strip()
            if line == '':
                continue
            key, value = line.split(':')
            key = key.strip()
            curr = options.get(key, None)
            if curr is None:
                options[key] = value.strip()
            elif  isinstance(curr, list):
                options[key] = curr + [val.strip() for val in value.split(',')]
            else:
                print "ERROR: Key '%s' was repeated but can only appear once in the info file." % key
        return options
    
    def __fetch(self, name):
        """Downloads the package into a local file."""
        cfg = Config()
        base = cfg['source'] + name
        baselatest = cfg['source'] + 'install/' + name +'-latest.dat';
        print "Get " + baselatest
        filehandle = urllib.urlopen(baselatest)
        base2 = cfg['source'] + filehandle.read()
        print "Get " + base2
        if self.__fetchIndividual(base2):
            return
        elif self.__fetchIndividual(base + '.tar.bz2'):
            return
        elif self.__fetchIndividual(base + '.tar.gz'):
            return
        elif self.__fetchIndividual(base + '.tgz'):
            return
        else:
            msg = "ERROR: Package %s could not be downloaded." % name
    
    def __fetchIndividual(self, url):
        try:
            filename, headers = urllib.urlretrieve(url)
            self.__filename = filename
            self.__file = tarfile.open(self.__filename, 'r')
            self.__file.errorlevel = 2
            return True
        except IOError:
            return False
        except tarfile.ReadError:
            return False
    
    def __getPostScript(self, tarfile, key, package):
        """
        Writes a post-install script to the file system and makes it ready to
        be executed.
        """
        scriptname = ('/tmp/%s-%s' % (package, key.split('/')[-1]))
        fh = open(scriptname, "w")
        fh.write(tarfile.extractfile(key).read())
        fh.close()
        os.chmod(scriptname, 0700)
        return scriptname
    
    def __executePostScript(self, scripts, script, execute = True):
        """
        Executes a post-install script. As a side-effect the script is removed
        from the file system.
        The execute param can be passed in to only execute the script if it is
        true. The script will always be deleted, though.
        """
        if script in scripts and scripts[script] is not None:
            if execute:
                print "Executing %s script %s" % (script, scripts[script])
                os.system(scripts[script])
            os.unlink(scripts[script])


class PackageRegistry(object):
    """Keeps track of all installed packages."""
    def __init__(self):
        self.__registry = Config()['registry']
        self.packages = self.__parseRegistry(self.__registry)
    
    def __parseRegistry(self, registry):
        """
        Parses the registry file retrieving information about all installed
        packages.
        """
        reg = {}
        if not os.path.exists(registry):
            return reg
        f = open(registry)
        for line in f.readlines():
            package, version = line.split(':')
            package, version = package.strip(), version.strip()
            pkg = reg.setdefault(package, [])
            if version not in pkg:
                pkg.append(version)
        f.close()
        return reg
    
    def register(self, package, version):
        """Registers a new version of a package."""
        pkg = self.packages.setdefault(package, [])
        if version not in pkg:
            pkg.append(version)
    
    def save(self):
        """Saves the current information into the package file."""
        f = open(self.__registry, 'w')
        for pkg, versions in self.packages.iteritems():
            for ver in versions:
                f.write(pkg + ':' + str(ver) + "\n")
        f.close()
    
    def isInstalled(self, package, version, comp='>='):
        """
        Checks if the package is installed with a version higher or equal to
        version. If so, the current version is returned. False is returned
        otherwise.
        """
        if not package in self.packages:
            return False
        for ver in self.packages[package]:
            if self.__compareVersions(ver, version, comp):
                return ver
        return False
    
    def __compareVersions(self, v1, v2, comp):
        """
        Compares two versions and returns true if the comp condition is true.
        Accepts >, >=, <, <= and = as comp.
        Examples:
            v1      v2      comp    result
             3       4        =     False
             4       4        =     True
             3       4        <     True
             5       4        <     False
        """
        v1 = self.__getVersionTuple(v1)
        v2 = self.__getVersionTuple(v2)
        if len(v1) != len(v2):
            # Never allow different kind of versioning
            return False
        cmps = []
        # Compare the individual parts, store results
        for item1, item2 in itertools.izip(v1, v2):
            if comp == '<':
                cmps.append((item1 < item2,  item1 == item2))
            elif comp == '<=':
                cmps.append((item1 <= item2, item1 == item2))
            elif comp == '>':
                cmps.append((item1 > item2,  item1 == item2))
            elif comp == '>=':
                cmps.append((item1 >= item2, item1 == item2))
            elif comp == '=':
                cmps.append((item1 == item2, item1 == item2))
        # Comparison logic for n components:
        #   1 to n-1: Comparison must return true or items must be equal
        #   n       : Comparison must return true
        for comparison in cmps[0:-1]:
            if comparison[0] == False and comparison[1] == False:
                return False
        if cmps[-1][0] == False:
            return False
        return True
    
    def __getVersionTuple(self, v):
        """
        Returns a tuple of the individual version components. Splits by
        dot and dash. All numeric values are converted to a number, so
        they sort numerically.
        """
        parts = []
        for part in re.split('[-\.]', v):
            val = part
            try:
                val = int(part)
            except:
                # Ignore exceptions, could not convert to int
                pass
            parts.append(val)
        return tuple(parts)

class Config(ConfigParser.SafeConfigParser):
    """
    Wraps the ConfigParser class, representing configuration settings
    for packager.
    """
    def __init__(self):
        # Params for interpolating in config file
        params = {
            # Empty string at end of os.path.join: Ensures that a slash is
            # always at the end of the path
            'pwd': os.path.join(os.getcwd(), sys.path[0], '')
        }
        ConfigParser.SafeConfigParser.__init__(self, params)
        self.read([sys.path[0] + '/packager.cfg'])
    
    def __getitem__(self, key):
        return self.get('packager', key)


c = Cli()
c.run()
