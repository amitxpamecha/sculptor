package org.sculptor.generator

import com.google.inject.Guice
import com.google.inject.Injector
import com.google.inject.Provider
import org.eclipse.emf.common.util.EList
import org.eclipse.xtext.junit4.InjectWith
import org.eclipselabs.xtext.utils.unittesting.XtextRunner2
import org.eclipselabs.xtext.utils.unittesting.XtextTest
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.sculptor.dsl.SculptordslInjectorProvider
import org.sculptor.dsl.sculptordsl.DslApplication
import org.sculptor.dsl.sculptordsl.DslModel
import org.sculptor.generator.ext.DbHelper
import org.sculptor.generator.ext.Helper
import org.sculptor.generator.ext.Properties
import org.sculptor.generator.transform.DslTransformation
import org.sculptor.generator.transform.DslTransformationModule
import org.sculptor.generator.transform.Transformation
import org.sculptor.generator.util.DbHelperBase
import sculptormetamodel.Application
import sculptormetamodel.Module
import sculptormetamodel.NamedElement

import static org.junit.Assert.*
import sculptormetamodel.Entity
import sculptormetamodel.Reference

@RunWith(typeof(XtextRunner2))
@InjectWith(typeof(SculptordslInjectorProvider))
class LibraryTransformationTest extends XtextTest{
	
	extension Properties properties

	extension Helper helper

	extension DbHelper dbHelper
	
	extension DbHelperBase dbHelperBase
	
	var DslApplication model
	var Provider<DslTransformation> dslTransformProvider
	var Provider<Transformation> transformationProvider
	var Application app
	
	protected static val SYSTEM_ATTRIBUTES = newImmutableSet("id", "uuid", "version",
		"createdBy", "createdDate", "updatedBy", "updatedDate", "lastUpdated", "lastUpdatedBy");
	
	
	@Before
	def void setupDslModel() {
		val Injector injector = Guice::createInjector(new DslTransformationModule)
		properties = injector.getInstance(typeof(Properties))
		helper = injector.getInstance(typeof(Helper))
		dbHelper = injector.getInstance(typeof(DbHelper))
		dbHelperBase = injector.getInstance(typeof(DbHelperBase))
		dslTransformProvider = injector.getProvider(typeof(DslTransformation))
		transformationProvider = injector.getProvider(typeof(Transformation))

		model = getDomainModel().app
		
		val dslTransformation = dslTransformProvider.get
		app = dslTransformation.transform(model)
		
		val transformation = transformationProvider.get
		app = transformation.modify(app)

	}

	def  getDomainModel() {
		
		testFileNoSerializer("library.btdesign", "library-person.btdesign")
		val dslModel = modelRoot as DslModel
		
		dslModel
		
        //val URI uri = URI::createURI(resourceRoot + "/" + "library.btdesign");
        //loadModel(resourceSet, uri, getRootObjectType(uri)) as DslModel;
	}
	
	
	def Module personModule() {		
		app.modules.namedElement('person')
    }

	// TODO: Move into helpers?
	def <T extends NamedElement> namedElement(EList<T> list, String toFindName) {
		list.findFirst[name == toFindName]
	}
	
	def Module mediaModule() {		
		app.modules.namedElement('media')
    }
    
    
    @Test
    def void assertApplication() {
        assertEquals("Library", app.getName());
    }



	def <NE extends NamedElement> void assertOneAndOnlyOne(EList<NE> listOfNamedElements, String... expectedNames) {
		val expectedNamesList = expectedNames.toList

		val actualNames = listOfNamedElements.map[ne|ne.name].filter[name | !SYSTEM_ATTRIBUTES.contains(name)].toList
				
		assertTrue("Expected: " + expectedNamesList + ", Actual: " + actualNames, actualNames.containsAll(expectedNamesList))
		assertTrue("Expected: " + expectedNamesList + ", Actual: " + actualNames, expectedNamesList.containsAll(actualNames))
		
	}

	@Test
    def void assertModules() {
        val modules = app.getModules();
        assertNotNull(modules);
        assertOneAndOnlyOne(modules, "media", "person");
    }

    @Test
    def void assertMediaModule() {
        val module = mediaModule;
        assertOneAndOnlyOne(module.domainObjects, "Library", "PhysicalMedia", "Media", "Book", "Movie",
                "Engagement", "MediaCharacter", "Genre", "Review", "Comment");
    }
    
    @Test
    def void assertPersonModule() {
        val module = personModule();
        assertOneAndOnlyOne(module.domainObjects, "Person", "Ssn", "Country", "Gender", "PersonName");
    }

    @Test
    def void assertPerson() {
        val person = personModule.domainObjects.namedElement("Person")
        assertOneAndOnlyOne(person.getAttributes(), "birthDate")
        assertOneAndOnlyOne(person.getReferences(), "ssn", "name", "sex")
        val ssn =  person.references.namedElement("ssn")
        assertTrue(ssn.isNaturalKey())
        val ssnNumber = ssn.to.attributes.namedElement("number")
        assertTrue(ssnNumber.isNaturalKey())
        val ssnCountry = ssn.to.references.namedElement("country")
        assertTrue(ssnCountry.isNaturalKey())
        assertTrue(person.isGapClass())
        assertFalse(ssn.getTo().isGapClass())
    }
    
    /**
     * Bidirectional one-to-many
     */
    @Test
    def void assertReferenceToPhysicalMediaFromLibrary() {
        val library = mediaModule.domainObjects.namedElement("Library")
        val mediaRef = library.references.namedElement("media")
        assertFalse(dbHelperBase.isInverse(mediaRef))
        assertEquals("LIB_REF", mediaRef.oppositeForeignKeyName);
    }


    /**
     * Bidirectional many-to-one
     */
    @Test
    def void assertReferenceToLibraryFromPhysicalMedia() {
        val physicalMedia = mediaModule.domainObjects.namedElement("PhysicalMedia");
        val libraryRef = physicalMedia.references.namedElement("library");
        assertTrue(dbHelperBase.isInverse(libraryRef));
        
        assertEquals("LIB_REF", libraryRef.databaseColumn);
        assertEquals("LIB_REF", libraryRef.foreignKeyName);
        assertEquals("MEDIA", libraryRef.oppositeForeignKeyName);
    }
    /**
     * Bidirectional many-to-many
     */
    @Test
    def void assertReferenceToMediaFromPhysicalMedia() {
        val physicalMedia = mediaModule.domainObjects.namedElement("PhysicalMedia") as Entity
        
        val mediaRef = physicalMedia.references.namedElement("media") as Reference
        assertFalse(dbHelperBase.isInverse(mediaRef));

        assertEquals("PHMED_MED", mediaRef.manyToManyJoinTableName);
        assertEquals("MEDIA_REF", mediaRef.databaseColumn);
        assertEquals("MEDIA_REF", mediaRef.foreignKeyName);
        assertEquals("PHYSICALMEDIA", mediaRef.oppositeForeignKeyName);

        val manyToManyObject = mediaRef.createFictiveManyToManyObject();
        assertEquals("PHMED_MED", manyToManyObject.databaseTable);
        assertOneAndOnlyOne(manyToManyObject.references, "media", "physicalMedia");
        val manyToManyObjectMediaRef = manyToManyObject.references.namedElement("media") as Reference;
        assertEquals("MEDIA_REF", manyToManyObjectMediaRef.databaseColumn);
        val manyToManyObjectPhysicalMediaRef = manyToManyObject.references.namedElement("physicalMedia") as Reference;
        assertEquals("PHYSICALMEDIA", manyToManyObjectPhysicalMediaRef.databaseColumn);
    }



}