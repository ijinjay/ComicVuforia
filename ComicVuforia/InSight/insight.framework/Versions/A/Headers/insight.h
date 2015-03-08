/*! \file insight.h
 * The main and unique header file that exposes the InSight interface.
 */

/*! \mainpage InSight SDK
*
* \section intro_sec Introduction
*
* InSight SDK is a cross platform software library which can be used to
* seamlessly integrate face analysis and facial expression recognition in third
* party applications. The SDK is extremely flexible, and allows retrieving
* tailored information depending on the specific requirements of the companies or
* individuals. Via a simple webcam the InSight SDK can be used to automatically
* analyze face videos in real time, and communicate the resulting information to
* a third party application. The information ranges from seven emotional
* categories (neutral,  happy, surprised, sad, afraid, angry and disgusted) to
* head pose, gaze, eye movements and age and gender of the subjects. The SDK is based
* on the following state-of-the art technologies developed in collaboration with
* the University of Amsterdam:
* - Face Detection
* - Facial Features Detection
* - Motion Tracking
* - Head Pose Estimation
* - Eye Localization
* - Gaze Estimation
* - Emotion Recognition
* - Age and Gender Estimation
*
* The SDK can be easily integrated in third party software as a collection of
* C++ shared libraries for Windows, Mac and Linux environments. The SDK
* requires an internet connection to function properly, as it will communicate
* with our API to validate the license.
*
* \section usage Usage
*
* InSight SDK works on a video sequence of frames. The first frame should be the
* initialization frame, after that all frames should be processes and the information about
* the user can be retrieved by using the getter functions.
* The following is the pseudo-code to retrieve and display the facial expressions
* of a user in each frame:
*
* \code
*
*  Initialize InSight and the capturing device/video input
*  for (;;)
*  {
*    capture >> frame; // get a new frame from the video stream
*
*    if (!insight.isInit())
*    {
*      insight.init(frame) // initialize InSight with the first frame
*    }
*    else
*    {
*      insight.process(frame) //process the new frame
*      insight.getEmotions(emotions) //retrieve the facial expressions
*      print(emotions) //print them to console
*    }
*  }
*
* \endcode
*
* For the full code, refer to the example implementation provided with the SDK. Additional usage examples can be provided upon request.
* The following is the pseudo-code to calibrate and obtain eye gaze information on each frame:
*
* \code
*
*  // fill a vector with at least nine calibration points
*  std::vector<cv::Point> calibrationPoints = nine calibration points;
*  std::vector<cv::Point>::iterator it = calibrationPoints.begin();
*  
*  // this vector will accumulate processed calibration points
*  std::vector<CalibInfo> calibCollection;
*  
*  cv::Mat frame;
*  bool isCalibrated = false;
*  int drawing  = 0;
*  while( grab( frame ) )
*  {
*    // initialize insight if necessary
*    if( !insight->isInit() && !insight->init( frame ) )
*    {
*      printError( insight->getError() );
*      break;
*    }
*  
*    // always process a frame
*    if( !insight->process( frame ) )
*    {
*      printError( "Failed to process" );
*      break;
*    }
*  
*    if( !isCalibrated )
*    {
*      cv::Point & calibrationPoint = *it;
*  
*      if( it != calibrationPoints.end() )
*      {
*        // draw calibrationPoint on screen for 25 frames
*        // to allow the user to fixate on the point
*        if( drawing < 25 )
*        {
*          drawDotOnScreen( calibrationPoint );
*          drawing++;
*        }
*        else
*        {
*          drawing = 0;
*  
*          // process calibration point
*          CalibInfo ci;
*          if( !insight->addCalibrationPoint( calibrationPoint, ci ) )
*          {
*            printError( "Failed to add calibration point" );
*            break;
*          }
*          // add processed calibration point to collection
*          calibCollection.push_back( ci );
*          // move to next calibration point
*          it++;
*        }
*      }
*      else
*      {
*        // calibrate using the processed calibration point collection
*        std::vector<cv::Point2f> calibErrors;
*        if(!insight->calibrate( calibCollection, calibErrors) )
*        {
*          printError( "Failed to calibrate" );
*          break;
*        }
*        isCalibrated = true;
*        // do something with the reprojection errors if required
*        printReprojectionErrors( calibErrors );
*      }
*    }
*    else
*    {
*      // insight get gaze
*      cv::Point estimatedGaze;
*      insight->getEyeGaze( estimatedGaze );
*      // do something with the acquired gaze point
*      drawOnScreen( estimatedGaze )
*    }
*  }
*
* \endcode
*
* \section requirements Requirements
*
* \subsection platformreq Platform requirements
* The minimum platform requirements.
* - Intel Core 2 Duo 1.6GHZ or better.
* - 2GB RAM
* - Input frames with a resolution of at least  640  480
* - Active Internet connection
*
* \subsection userreq User requirements
*
* InSight SDK is designed for a single-user scenario, in which the user is around 60 cm away from the camera (eg: like in front of a desktop or a laptop computer).
* The following user requirements should be met in order to use the InSight SDK.
* - The user should be approximately at the center of the camera image that is used for initialization
* - The user should sit at 60 centimeters from the screen and the camera (attached to the top center of the screen)
* - The user should assume a frontal face position with a neutral expression during initialization
* - For gaze estimation, the user should not move his head too much during calibration
*
* \subsection environmentreq Environment requirements
* The following environment conditions should be met in order to use the InSight SDK.
* - Good illumination so face is clearly visible
* - No light source behind the user (windows, lamps etc)
*
*/

#ifndef INSIGHT_H
#define INSIGHT_H

/*! \cond PRIVATE */
#include <opencv2/opencv.hpp>
#include <vector>
#include <string>
#include <stdint.h>

#ifdef ANDROID
#include <jni.h>
#endif

/*! \endcond */

/** @cond */
// Helper definitions for shared library support
// http://gcc.gnu.org/wiki/Visibility
#if defined _WIN32 || defined __CYGWIN__
  #define INSIGHT_DLL_IMPORT __declspec(dllimport)
  #define INSIGHT_DLL_EXPORT __declspec(dllexport)
  #define INSIGHT_DLL_LOCAL
#else
  #if __GNUC__ >= 4
    #define INSIGHT_DLL_IMPORT __attribute__ ((visibility ("default")))
    #define INSIGHT_DLL_EXPORT __attribute__ ((visibility ("default")))
    #define INSIGHT_DLL_LOCAL  __attribute__ ((visibility ("hidden")))
  #else
    #define INSIGHT_DLL_IMPORT
    #define INSIGHT_DLL_EXPORT
    #define INSIGHT_DLL_LOCAL
  #endif
#endif

#ifdef INSIGHT_DLL               // defined if InSight is compiled as a shared library
    #ifdef INSIGHT_EXPORTS       // defined if compiling InSight
      #define INSIGHT_API INSIGHT_DLL_EXPORT
    #else
      #define INSIGHT_API INSIGHT_DLL_IMPORT
    #endif
    #define INSIGHT_LOCAL INSIGHT_DLL_LOCAL
#else                               // InSight is a static library
    #define INSIGHT_API
    #define INSIGHT_LOCAL
#endif


// Deprecation macros
#ifdef __GNUC__
  #define DEPRECATED(func) func __attribute__ ((deprecated))
#elif defined(_MSC_VER)
  #define DEPRECATED(func) __declspec(deprecated) func
#else
  #pragma message("WARNING: You need to implement DEPRECATED for this compiler")
  #define DEPRECATED(func) func
#endif
/** @endcond */

/*! \brief FeaturesRequest defines which features will be extracted for the person object retrieved by getCurrentPerson.
 *  To be used along with server operation mode to define the credits to be used. On developer or redistribution
 *  operation mode getCurrentPerson should use the default parameter (ALL_FEATURES)
 */
struct INSIGHT_API FeaturesRequest {
  bool age;
  bool gender;
  bool mood;
  bool head_pose;
  bool head_gaze;
  bool eye_gaze;
  bool eye_location;
  bool attention_span;
  bool clothing_colors;
  bool emotions;
  bool tracking_points;
  bool returning_customer;
};

const FeaturesRequest ALL_FEATURES = { true, true, true, true, true, true, true, true, true, true, true, true }; /*!< Request all features */

class PersonImpl;

class INSIGHT_API Person
{
public:

  /*! \brief Person structure returned by InSight SDK
   *
   * */
  Person( PersonImpl & p );
  Person( const Person & p );
  Person & operator=( const Person & p );


  /*! \brief Person structure destructor
   *
   * */
  ~Person();

  /*! \brief Returns the person Identifier (label). Each person has a unique ID.
   * Note: this number does not represent the number of people.
   *
   * @return the unique ID of the person
   * */
  const std::string & getID();

  /*! \brief Returns the estimated age for the person. This number should be an indication
   * of the age category, rather than an accurate estimation of age. The function returns
   * 0 if the age estimation is not available yet.
   *
   * @return the estimated age in years.
   * */
  int getAge();

  /*! \brief Returns the estimated gender for the person
   *
   * @return A value between -1 (Male) and +1 (Female). Values around 0 should be
   * considered as "uncertain".
   * */
  float getGender();

  /*! \brief Returns a rectangle defining the x, y, width and height of the face
   * of the person in image coordinates.
   *
   * @return cv::Rect with the face coordinates
   * */
  cv::Rect  getFaceRect();

  /*! \brief Returns the estimated mood of the person.
   *
   * @return values in the range [-1,1]. Positive values correspond to positive mood
   * (eg: happy), negative values correspond to negative mood (eg: sad), near zero values
   * mean neutral mood
   * */
  float getMood();

  /*! \brief Returns the estimated head yaw of the person.
   *
   * @return Yaw value between -1 and 1, where -1 is -40 degrees, and +1 is +40 degrees.
   * */
  float getHeadYaw();

  /*! \brief Returns the estimated head pitch of the person.
   *
   * @return Pitch value between -1 and 1, where -1  is -30 degrees, and +1 is +30 degrees.
   * */
  float getHeadPitch();

  /*! \brief Returns the estimated head roll of the person.
   *
   * @return Roll value between -1 and 1, where -1  is -30 degrees, and +1 is +30 degrees.
   * */
  float getHeadRoll();

  /*! \brief Returns the estimated head gaze of the person.
   *
   * @return Gaze coordinate in 2D.
   * */
  cv::Point getHeadGaze();

  /*! \brief Returns the estimated eye gaze of the person.
   *
   * @return Gaze coordinate in 2D.
   * */
  cv::Point getEyeGaze( bool clampToScreen = true );

  /*! \brief Returns the position in pixels of right eye of the person, relative to the
   * input image.
   *
   * @return cv::Point with the right eye coordinates
   * */
  cv::Point getRightEye();

  /*! \brief Returns the position in pixels of left eye of the person, relative to the
   * input image.
   *
   * @return cv::Point with the left eye coordinates
   * */
  cv::Point getLeftEye();

  /*! \brief Returns the timestamp of the current person as elapsed time since the
   * InSight initialization.
   *
   * @return value in milliseconds
   * */
  int64_t getTime();

  /*! \brief Returns the estimated attention time of a person.
   *
   * The estimated attention time represents the time in which the person is actively looking
   * towards the camera. If the person is not observed for more than 3 seconds, the attention span will reset to 0.
   *
   * @return value in milliseconds
   * */
  int64_t getAttentionSpan();

  /*! \brief Checks if a person is returning since a period of time
   *
   * @return true if a person is returning since a period of time
   */
  bool isReturningCustomer();

  /*! \brief Retrieve a set of dominant clothing colors in RGB format.
   * Returns false if the cloth patch is not within the image plane. The number of colors to be retrieved
   * can be set in settings.ini.
   *
   * @return a vector of the top colors in RGB values (0-255)
   */
  std::vector<std::vector<int> > & getClothingColors();

  /*! \brief Checks if a person is recognized from database models. NOTE: This function can
   * only be used when Face Recognition is in use.
   *
   * @return true if person is recognized from a database model
   */
  bool isFromDatabase();

  /*! \brief Returns the current emotion intensities
   *
   * Return a vector of floats in [0,1] which represent the current emotion intensities:
   * - vector[0]: happy
   * - vector[1]: surprised
   * - vector[2]: angry
   * - vector[3]: disgusted
   * - vector[4]: afraid
   * - vector[5]: sad
   *    
   * @return The vector with emotion intensities
   */
  std::vector<float> & getEmotions();

  /*! \brief Returns 2D mask points that are tracked on the face
   *
   * Returns a vector of 2D points that are being tracked on
   * the face. These points can be used for visualizing the current
   * tracking mask. Each point is represented in X and Y coordinates
   * with respect to the top left corner of the input frame.
   *
   * @remarks Does not use a credit
   * @return Tracking points that represent the face mask
   */
  std::vector<cv::Point> & getTrackingPoints();

  /*! \brief Returns the current action units
   *
   * TODO
   *
   * @return The vector with action units
   */
  std::vector<float> & getActionUnits();

private:
  PersonImpl * mPersonImpl;
};


/*! \brief OperationMode enumerates all possible InSight operation modes
 */
enum OperationMode {
  DEVELOPER,          /*!< Default mode. Used for development on a new or previously registered developer machine.*/
  REDISTRIBUTION,     /*!< Redistribution mode. Used to produce the final binary to be distributed to your clients.*/
  SERVER              /*!< Server mode. Used on a server machine in combination with a InSight server license.*/
};

  /*! \brief CalibInfo represents a processed calibration point
   *
   */
struct CalibInfo
{
  /*! \brief Location of the calibration point on the screen
   *
   * Screen position of the calibration point in pixel coordinates. The origin
   * is in the left upper corner.
   */
  cv::Point mScreenPos;
  /*! \brief Location of the calibration point on calibration plane
   *
   * This parameter is part of the internal working, and should not be used.
   * it is forwarded for proper serialization of CalibInfo objects.
   */
  cv::Point2f mCalibPlanePos;
  /*! \brief 3D position and orientation of the head with
   * respect to the camera.
   *
   * Represents the position of the head at the time the calibration point
   * was recorded. The first three values are the x, y and z positions
   * with respect to the camera. The last three values are rotations on the x, y and z
   * planes (in radians).
   */
  std::vector<float> mHeadPose;
  /*! \brief Location of the left eye center
   *
   * Location of the left eye center in pixel coordinates within the mLeftEyePatch matrix.
   */
  cv::Point2i mLeftEyePos;
  /*! \brief Location of the right eye center
   *
   * Location of the right eye center in pixel coordinates within the mRightEyePatch matrix.
   */
  cv::Point2i mRightEyePos;
  /*! \brief Right eye patch image
   *
   * A matrix repesenting the right eye patch image.
   */
  cv::Mat mRightEyePatch;
  /*! \brief Left eye patch image
   *
   * A matrix representing the left eye patch image.
   */
  cv::Mat mLeftEyePatch;
};


/*! \brief ImageQuality contains the qualities returned by the InSight::getImageQuality function
 *
 * Values are in the range 0 and 1, where 1 is optimal conditions. Values below ~0.4 need condition
 * adjustements. Optimal conditions are:
 * - 60cm distance from the screen.
 * - Face centered in respect to the camera.
 * - Face properly illuminated.
 * - Low quantity of background light.
 */
struct ImageQuality
{
  bool  faceDetected;            /*!< States whether a face has been detected  */
  float faceScale;               /*!< Scale of the face in respect to the image dimensions  */
  float faceCenterPosition;      /*!< Position of the face in respect to the center of the image  */
  float faceIllumination;        /*!< Illumination of the face  */
  float backgroundIllumination;  /*!< Quantity of light in the background  */
};

/*! \brief ColorSpace enumerates all supported color spaces for conversion of raw image data to an OpenCV BGR format
 */
enum ColorSpace {
  RGB = 0, /*!< data is in RGB format */
  BGR,     /*!< data is in BGR format */
  YUV,     /*!< data is in YUV format */
  YUV420,  /*!< data is in YUV420 format, mainly used for Android cameras */
  BMP      /*!< data is in BitMap format, mainly used for Android cameras */
};

class InSightImpl;

class INSIGHT_API InSight
{
public:
  /**********************************
  * Engine Initialization functions *
  **********************************/

  /*! \brief Instantiate the SDK.
   *
   * @param[in] dataDir    Path to the InSight data directory containing the SDK resource files
   * @param[in] opMode     OperationMode of current InSight instance. Default, DEVELOPER
   * @remarks Does not use a credit
   */

#ifdef ANDROID
  InSight( jobject context, std::string mDataDir = "./data/", const OperationMode opMode = DEVELOPER );
#else
  InSight( std::string mDataDir = "./data/", const OperationMode opMode = DEVELOPER );
#endif // ANDROID

  ~InSight();

  /*! \brief Returns the current version of the SDK
   *
   * This functions returns the InSight version as a string. The string
   * is in the form of xx.yy where 'xx' are the two digits used for the
   * major version number and 'yy' are the two digits used for the minor
   * version number.
   *
   * @remarks Does not use a credit
   * @return string The current version number of the SDK
   */
  static std::string getVersion();

  /*! \brief Authenticates an InSight instance against the secure server
   *
   * This function will connect and authenticate an InSight instance, using
   * the provided license key. It has the optional ability to connect
   * through a proxy server.
   *
   * @remarks Does not use a credit
   * @param[in] key             The license key provided by Sightcorp
   * @param[in] proxyAddress    Optional proxy address
   * @param[in] proxyPort       Optional proxy port
   * @param[in] proxyUserName   Optional user name
   * @param[in] proxyPassword   Optional password
   * @return Success or failure
   */
  bool authenticate( const std::string & key,
                     const std::string & proxyAddress  = "",
                     const int           proxyPort     = 0,
                     const std::string & proxyUserName = "",
                     const std::string & proxyPassword = "" );

  /*! \brief returns if this InSight instance is authenticated with the server or not */
  bool isAuthenticated();

  /*! \brief Initialize an InSight instance using the first frame of the video input
   *
   * This function must be called once on the first frame of the frame sequence to be processed.
   * Prior to passing the first frame to init, it should be checked
   * for proper light conditions and face placement. This can be done using
   * InSight::getImageQuality function. Additionally, the face contained
   * in the first frame must be frontal with a neutral expression. Internally, the
   * function fits a generic face model which is then tracked
   * using InSight::process calls on subsequent frames of the video.
   *
   * @remarks Starts a new processing session. Does not use a credit
   * @pre InSight instance must be successfully authenticated using the InSight::authenticate function
   * @param[in] inImage    The current video frame
   * @return Success or failure
   */
  bool init( const cv::Mat & inImage );

  /*! \brief Initialize an InSight instance using the first frame of the video input
   *
   * This function must be called once on the first frame of the frame sequence to be processed.
   * Prior to passing the first frame to init, it should be checked
   * for proper light conditions and face placement. This can be done using
   * InSight::getImageQuality function. Additionally, the face contained
   * in the first frame must be frontal with a neutral expression. Internally, the
   * function fits a generic face model which is then tracked
   * using InSight::process calls on subsequent frames of the video.
   *
   * @remarks Starts a new processing session. Does not use a credit
   * @pre InSight instance must be successfully authenticated using the InSight::authenticate function
   * @param[in] inImage    The current video frame
   * @param[in] inFace     Optional face location in input image
   * @return Success or failure
   */
  bool init( const cv::Mat & inImage, const cv::Rect & inFace );

  /*! \brief Returns if this InSight instance is initialized or not */
  bool isInit();

  /*! \brief Resets the mask point deformation
   *
   * This function resets the mask points to their original locations on the subject face.
   * Can be used to to manually reset unnatural mask deformations.
   */
  void resetMaskPoints();

  /*! \brief reset InSight to reimburse credits
   *
   * This optional function resets the InSight instance.
   * If called within 7 seconds after InSight::init, all credits consumed during current
   * session are reimbursed. Can be used in case of faulty initialization or other
   * malfunction. This function is called internally by InSight::init if InSight::isInit() is true.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   */
  void reset();

  /*****************************
  * Credits Counting Functions *
  *****************************/

  /*! \brief Returns the amount of remaining credits for the current license
   *
   * This function can be called after the user has authenticated with the server.
   * In DEVELOPER OperationMode it returns the amount of seconds remaining until
   * the license expiration. In SERVER OperationMode it returns the amount of usages
   * remaining. In REDISTRIBUTION OperationMode or in case of error it returns -1,
   * indicating that the remaining credits information is not available.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully authenticated using the InSight::authenticate function
   * @return The remaining amount of credits for this license or -1
   */
  int getRemainingCredits();

  /***************************
  * InSight Getter Functions *
  ***************************/

  /*! \brief Process current video frame
   *
   * This function must be called on all the frames of the video sequence, except for the
   * first one that is used for initialization. This function computes all the properties
   * (like emotions) of the tracked face. These properties can then be retrieved by getter
   * functions (like InSight::getEmotions)
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inImage The current video frame
   * @return Success or failure
   * */
  bool process( const cv::Mat & inImage );

  /*! \brief Process current video frame
   *
   * This function must be called on all the frames of the video sequence, except for the
   * first one that is used for initialization. This function computes all the properties
   * (like emotions) of the tracked face. These properties can then be retrieved by getter
   * functions (like InSight::getEmotions)
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inImage The current video frame
   * @return Success or failure
   * */
  bool process( const cv::Mat & inImage, const cv::Rect & inFace );

  /*! \brief Get the properties of the person being processed
   *
   * Call this function to retrieve the Person object in the current frame. The process() function
   * needs to be called before this. The person object can then be queried with getters
   * (see Person class methods)
   *
   * @param[out] person The detected person in the current frame
   *
   * @return true if the function is successfully executed
   * */
  bool getCurrentPerson( Person *& person, const FeaturesRequest & features = ALL_FEATURES );

  /*! \brief Returns the current emotion intentsities
   *
   * Return a vector of floats which represent the current emotion
   * intensities:
   * - vector[0]: neutral
   * - vector[1]: happy
   * - vector[2]: surprised
   * - vector[3]: angry
   * - vector[4]: disgusted
   * - vector[5]: afraid
   * - vector[6]: sad
   *
   * The emotion intensity values are represented in the range [0.0, 1.0]
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outEmotions    The vector with emotion intentsities
   * @return Success or failure
   */
  bool getEmotions( std::vector<float> & outEmotions );

  /*! \brief Returns the intensity of 12 motion units.
   *
   * Returns the intensity of 12 motion units (in cm). The motion units
   * represent the motion of a group of tracking points of the mask
   * (patches) These are:
   * - vector[0]: vertical movement of upper lips
   * - vector[1]: vertical movement of lower lips
   * - vector[2]: horizontal movement of left mouth corner
   * - vector[3]: vertical movement of left mouth corner
   * - vector[4]: horizontal movement of right mouth corner
   * - vector[5]: vertical movement of right mouth corner
   * - vector[6]: vertical movement of right eyebrow
   * - vector[7]: vertical movement of left eyebrow
   * - vector[8]: vertical movement of right cheek
   * - vector[9]: vertical movement of left cheek
   * - vector[10]: vertical movement of right eyelid
   * - vector[11]: vertical movement of left eyelid
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outIntensities    The intensity of the motion units
   * @return Success or failure
   */
  bool getMotionUnits( std::vector<float> & outIntensities );

  /*! \brief Returns 2D mask points that are tracked on the face
   *
   * Returns a vector of 2D points that are being tracked on
   * the face. These points can be used for visualizing the current
   * tracking mask. Each point is represented in X and Y coordinates
   * with respect to the top left corner of the input frame.
   *
   * @remarks Does not use a credit
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outPoints    Tracking points that represent the face mask
   * @return Success or failure
   */
  bool getMaskPoints( std::vector<cv::Point> & outPoints );

  /*! \brief Returns 3D mask points that are tracked on the face
   *
   * Returns a vector of 3D points that are being tracked on the 3D face mesh.
   * The points are expressed in X, Y and Z coordinates where the origin stands
   * in the center of the camera (for X and Y) and 60cm far from the camera (for Z).
   * X and Y are expressed in cm and Z in mm.
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outPoints    Tracking 3d points of the face mesh
   * @return Success or failure
   */
  bool getMaskPoints3D( std::vector<cv::Point3f> & outPoints );

  /*! \brief Returns the mask quality measure
   *
   * Returns a double that represents 2D mask quality. Lower is better.
   *
   * @remarks Does not use a credit
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outQuality    Mask quality value
   * @return Success or failure
   */
  bool getMaskQuality( double & outQuality );

  /*! \brief Returns the 3D position and orientation of the head with
   * respect to the camera.
   *
   * The first three values are the x, y and z position with respect
   * to the camera (see InSight::getMaskPoints3D). The last three values are
   * rotations on the x, y and z planes (in radians).
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outHeadpose  A vector of floats representing the headpose
   * @return Success or failure
   */
  bool getHeadPose( std::vector<float> & outHeadpose );

  /*! \brief Returns a point representing the head gaze location
   *
   * Returns a point representing the head gaze location on the screen,
   * in terms of X and Y coordinates (in pixels) with origins in the top 
   * left corner of the screen.
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outHeadGaze    The head gaze in pixel coordinates
   * @return Success or failure
   */
  bool getHeadGaze( cv::Point & outHeadGaze );

  /*! \brief Returns the 2D position of the left and right eye centers.
   *
   * Returns the 2D position of the left and right eye centers with respect
   * to the input frame.
   *
   * eg:
   * - vector[0].x= x coordinate of the left eye.
   * - vector[1].y= y coordinate of the right eye.
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[out] outLocations The 2d positions of the eye centers
   * @return Success or failure
   */
  bool getEyeLocations( std::vector<cv::Point> & outLocations );

  /*! \brief Returns a point representing the eye gaze location
   *
   * Returns a point representing the eye gaze location on the screen in
   * pixel coordinates. Gaze estimation assumes that the user is 60 cm away
   * from the screen.
   *
   * @remarks Uses one credit per session
   * @pre This function requires a successfull gaze calibration, performed with InSight::calibrate
   * Following it can be used after each successfull InSight::process call
   * @param[out] outEyeGaze The eye gaze location on the screen in pixel coordinates
   * @return Success or failure
   */
  bool getEyeGaze( cv::Point & outEyeGaze, bool clampToScreen = true );

  /*! \brief Corrects a given eyegaze by analyzing the context around it
   *
   * Corrects a given eyegaze location by analyzing the context that is gazed upon.
   * The radius parameter allows to vary how much of the context around the gaze
   * dot is examined. Can provide an increase in gaze estimation accuracy.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inContext Image of the context gazed upon. Must have dimensions equal to screen resolution.
   * @param[in] inRadius Radius around the gaze dot that will be analyzed
   * @param[in] inEyeGaze Eye gaze point to be corrected.
   * @return Success or failure
   */
  bool correctEyeGaze( const cv::Mat & inContext, int inRadius, cv::Point & inEyeGaze );

  /*! \brief Returns the eye gaze location error for a given point
   *
   * Returns the euclidean distance between inGazeTestPoint and the actual gaze
   * location that is estimated upon the last processed image.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inGazeTestPoint Expected gaze location
   * @param[out] error Absolute distance between expected and estimated gaze location
   * @return Success or failure
   */
  bool getEyeGazeError( const cv::Point inGazeTestPoint, double & outError );

  /*! \brief Returns the positions of faces present in the input image
   *
   * Returns a vector of rectangles, each representing the coordinates of
   * a face in the image.
   *
   * @remarks Does not use a credit
   * @param[in] inImage The image on which to search
   * @return A vector of rectangles
   */
  std::vector<cv::Rect> getFaces( const cv::Mat & inImage );

  /*! \brief Returns the biggest face in the image (ie: closest to camera)
   *
   * @remarks Does not use a credit
   * @param[in] inImage The image on which to search
   * @return The rectangle corresponding to biggest face
   */
  cv::Rect getFace( const cv::Mat & inImage );

  /*! \brief Returns the age of a person in the input image
   *
   * Returns the age of a person in the supplied image.
   * The detected age groups are defined as:
   *  - 0 : 10-20
   *  - 1 : 20-30
   *  - 2 : 30-40
   *  - 3 : 40-50
   *  - 4 : 50-60
   *  - 5 : 60+
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[in] inImage The input image
   * @param[out] outAge The age group
   * @return Success or failure
   */
  bool getAge( const cv::Mat & inImage, int & outAge );

  /*! \brief Returns the gender of a person in the input image
   *
   * Returns the gender of a person in the supplied image.
   *
   * The detected gender:
   *  - 0 : male
   *  - 1 : female
   *
   * @remarks Uses one credit per session
   * @pre This function can be used after each successfull InSight::process call
   * @param[in] inImage The input image
   * @param[out] outGender The detected gender
   * @return Success or failure
   */
  bool getGender( const cv::Mat & inImage, int & outGender );

  /************************
  * Calibration Functions *
  ************************/

  /*! \brief Adds a calibration point to improve eye gaze
   *
   * Adds a calibration point to the eye gaze calibration set. Once sufficient
   * points are collected, InSight::calibrate should be called to complete calibration.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inPoint The calibration point
   * @param[out] outCalibInfo Internal representation of the processed calibration point
   * @return Success or failure
   */
  bool addCalibrationPoint( const cv::Point2i & inPoint, CalibInfo & outCalibInfo );

  /*! \brief Calibrates eye gaze tracker
   *
   * Calibrates eye gaze tracker after enough points are added using InSight::addCalibrationPoint
   * It is advised to collect at least nine points before calling this function.
   *
   * @remarks Does not use a credit
   * @pre Enough points must be added using InSight::addCalibrationPoint
   * @param[out] outReprojectionErrors a vector containing reprojection errors on each calibratin point
   * @return Success or failure
   */
  bool calibrate(std::vector<cv::Point2f> & outReprojectionErrors);

  /*! \brief Calibrates eye gaze tracker
   *
   * Calibrates eye gaze tracker using the supplied calibration point collection.
   * Passing a collection of at least nine CalibInfo objects is advised.
   *
   * @remarks Does not use a credit
   * @pre InSight instance must be successfully initialized using the InSight::init function
   * @param[in] inCalibInfo A vector of CalibInfo structs, representing the calibration collection
   * @param[out] outReprojectionErrors a vector containing reprojection errors on each calibratin point
   * @return Success or failure
   */
  bool calibrate(const std::vector<CalibInfo> & inCalibInfo, std::vector<cv::Point2f> & outReprojectionErrors);

  /*! \brief Serializes a CalibInfo object
   *
   * Serializes a CalibInfo object, representing a processed calibration point.
   * Can be used to save calibration points for purposes of reprocessing a video.
   *
   * @remarks Does not use a credit
   * @param[in] path string representing the path and filename to serialize to
   * @param[in] inCalibInfo CalibInfo object to be serialized
   * @return Success or failure
   */
  bool serializeCalibration( const std::string & path, const CalibInfo & inCalibInfo );

  /*! \brief Deserializes a previously saved CalibInfo object
   *
   * Deserializes a previously saved CalibInfo object, representing a calibration point.
   * Can be used to load calibration points for purposes of reprocessing a video.
   *
   * @remarks Does not use a credit
   * @param[in] path string representing the path and filename
   * @param[in] inCalibInfo CalibInfo object to be deserialized
   * @return Success or failure
   */
  bool deserializeCalibration( const std::string & path, CalibInfo & outCalibInfo );


  /***************************
  * Error Handling Functions *
  ***************************/

  /*! \brief Returns the error code
   *
   * In case an InSight function returns false, it is possible to acquire an
   * error code, representing a specific issue. See InSight::getError for a
   * human readable representation of the error.
   *
   * Error code levels:
   *  - 0  No errors
   *  - 1X Connection errors
   *  - 2X Authentication errors
   *  - 3X Allowance errors
   *  - 4X Functional errors
   *
   * @remarks Does not use a credit
   * @return A code representing an error
   */
  int getErrorCode();

  /*! \brief Return the current error string
   *
   * In case an InSight function returns false, it is possible to acquire an
   * error string describing the issue.
   *
   * @remarks Does not use a credit
   * @return A string containing the error description
   */
  std::string getErrorDescription();

  /********************
  * Utility Functions *
  ********************/

  /*! \brief returns width of screen in pixels */
  static int getScreenWidthRes();

  /*! \brief return height of screen in pixels */
  static int getScreenHeightRes();

  /*! \brief returns width of screen in inches */
  static float getScreenWidthInch();

  /*! \brief return height of screen in inches */
  static float getScreenHeightInch();

  /*! \brief set the width of screen in pixels */
  static void setScreenWidthRes( int w );

  /*! \brief set the height of screen in pixels */
  static void setScreenHeightRes( int h );

  /*! \brief set the width of screen in inches */
  static void setScreenWidthInch( float w );

  /*! \brief set the  height of screen in inches */
  static void setScreenHeightInch( float h );

  /*! \brief set age classification on/off
   *
   * @param[in] use
   */
  static void useAge( bool use );

  /*! \brief set gender classification on/off
   *
   * @param[in] use
   */
  static void useGender( bool use );

  /*! \brief Evaluates the quality of a frame
   *
   * This functions returns the quality of the frame passed as argument
   * in terms of face distance from the screen, face position, face
   * illumination and backlight conditions. A return value above 0.5 means
   * that the image conditions are good enough for initialization. Additionally
   * it fills a supplied structure with numbers indicating the specific conditions
   * of the input frame (see ImageQuality)
   *
   * @remarks Does not use a credit
   *
   * @param[in] inImage    The current video frame
   * @param[out] outQualityProperties    A structure containing the image quality properties
   *
   * @return float A value between 0.0 (bad quality) and 1.0 (optimal quality) representing the value of the worst property
   */
  float getImageQuality( const cv::Mat & inImage, ImageQuality & outQuality );

  /*! \brief Converts image data to an OpenCV BGR formatted matrix
   *
   * This function is intended to suport the user with image format conversion. This function
   * converts an image pointed by data_array from a color space specified as input argument into
   * a standard OpenCV BGR format accepted by the SDK.
   *
   * @param[in] data_array    A pointer to the buffer containing the image data to be converted
   * @param[in] width         The width of the image
   * @param[in] height        The height of the image
   * @param[in] colorSpace    The color space of the image data (see ColorSpace)
   *
   * @return An OpenCV matrix in BGR format
   */
  static cv::Mat convert( void *data_array, int width, int height, ColorSpace colorSpace );
private:

  /* InSight objects cannot be copied */
  INSIGHT_LOCAL InSight( const InSight & );
  INSIGHT_LOCAL InSight & operator=( const InSight & );

  InSightImpl * mInSightImpl;

};


#endif /* INSIGHT_H */
