package configuration;

import java.io.IOException;
import java.util.Properties;

public class ConfigurationProperties {
	private Properties configFile;
	
	/**
	 * Constructor of the class
	 */
	public ConfigurationProperties() {
		initConfig("/config.properties");
	}
	/**
	 * @param configFileName The name of the configuration file 
	 * to be read.
	 * 
	 * this method loads the configuration file of the system
	 * **/
	public void initConfig(String configFileName) {
		configFile = new Properties();
		try {
			configFile.load(this.getClass().getClassLoader()
					.getResourceAsStream(configFileName));
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.out.println("Could not load property files");
		}		
	}
	
	
	/**
	 * @param key the Key of the value to look for
	 * @return The value related to the key
	 */
	public String getStringValue(String key){
		return configFile.getProperty(key);
	}
}
